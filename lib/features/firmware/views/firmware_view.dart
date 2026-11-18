import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/core/theme/accessible_buttons.dart';
import 'package:redfishopenbmc/features/firmware/firmware_controller.dart';
import 'package:redfishopenbmc/features/firmware/firmware_providers.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/redfish_task.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Human-readable firmware image size for the upload size warnings (issue
/// #008). Pure and locale-independent so it can be unit-tested and produce a
/// stable merged-semantics label: bytes below 1 KiB, whole KiB below 1 MiB,
/// otherwise one-decimal MiB (the 100 MiB soft threshold reads as "100.0 MB").
String formatFirmwareImageSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${bytes ~/ 1024} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Firmware & update management screen for a single system (issue #008).
///
/// Rendered only when the system advertises `UpdateService`
/// ([SystemFeatures.firmwareUpdate] is `true`); when the capability is absent
/// (or discovery is incomplete) this view renders nothing so there is never a
/// placeholder. Surfaces the firmware inventory cards and a SimpleUpdate form
/// driven by [FirmwareController].
class FirmwareView extends ConsumerStatefulWidget {
  /// Creates a [FirmwareView] for [systemId].
  const FirmwareView({required this.systemId, super.key});

  /// Logical id of the system this view is scoped to.
  final String systemId;

  @override
  ConsumerState<FirmwareView> createState() => _FirmwareViewState();
}

class _FirmwareViewState extends ConsumerState<FirmwareView> {
  /// Dropdown sentinel for the "Service default" apply-time choice — not a
  /// real mode; maps back to `null` so the request body omits
  /// `@Redfish.OperationApplyTime`.
  static const String _kServiceDefault = '_serviceDefault';

  final TextEditingController _imageUriController = TextEditingController();
  String _transferProtocol = 'HTTP';

  // The local image chosen for the push-upload flow (#008/#020 file-picker
  // integration). `null` = nothing selected (or the user cancelled the
  // dialog) — the Upload control stays disabled.
  XFile? _pickedImage;

  // Byte length of [_pickedImage], read at pick time so the build method can
  // apply the `MaxImageSize` hard gate / 100 MiB soft warning synchronously
  // (issue #008). `null` = no selection or the platform could not report a
  // size — no size-based gating in that case.
  int? _pickedSize;

  // The selected push-apply-time mode (`@Redfish.OperationApplyTime`,
  // #008/#020 apply-time selection). `null` = "Service default" — the
  // service's current `HttpPushUriApplyTime.ApplyTime` mode applies and the
  // client MUST NOT assume Immediate (the schema-only contract: the mode is
  // whatever the service advertises and applies it its own way).
  String? _applyTime;

  @override
  void initState() {
    super.initState();
    // Auto-load the inventory on first paint (post-frame so the notifier is
    // mounted and watchers are ready).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(firmwareControllerProvider(widget.systemId).notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _imageUriController.dispose();
    super.dispose();
  }

  // Push-upload availability (#008/#020): shown only when the service
  // advertises a push URI — the same data the upload transport resolves
  // (`HttpPushUri` single-push, `MultipartHttpPushUri` multipart, or both).
  // Not advertised → no card, no placeholder (the capability-gated pattern).
  bool _pushAvailable(FirmwareUiState ui) =>
      (ui.info?.httpPushUri != null) || (ui.info?.multipartHttpPushUri != null);

  /// True while an inventory load or a push upload is in flight — the shared
  /// disable condition for both push-upload controls.
  bool _isBusy(FirmwareUiState ui) => ui.loading || ui.uploading;

  /// A queued/running task with a known monitor URI can be cancelled (issue
  /// #008). A terminal [FirmwareUiState.lastResult], a missing URI, or an
  /// in-flight cancellation hide the Cancel control.
  bool _taskCancellable(FirmwareUiState ui) {
    final String? uri = ui.lastTask?.taskUri;
    return uri != null &&
        uri.isNotEmpty &&
        ui.lastResult == null &&
        !ui.cancelling;
  }

  /// The renderable apply-time options for the push-upload card: only the
  /// modes the service itself advertises (`HttpPushUriOptions.
  /// HttpPushUriApplyTime.ApplyTime@Redfish.AllowableValues`), never an
  /// assumed set; an empty list means the card shows no selector at all.
  List<String> _applyTimeOptions(FirmwareUiState ui) =>
      ui.info?.httpPushApplyTimes ?? const <String>[];

  /// Opens the system file dialog (via [firmwareImagePickerProvider]) and
  /// stores the picked image plus its byte length; a cancel (null) keeps the
  /// current selection — the Upload control then stays disabled.
  Future<void> _chooseImage(FirmwareUiState ui) async {
    if (_isBusy(ui)) return;
    final XFile? picked = await ref.read(firmwareImagePickerProvider)();
    if (picked == null || !mounted) return;
    // The size drives the MaxImageSize hard gate / 100 MiB soft warning. Some
    // platforms cannot report it, so treat a failure as "unknown" (no gating)
    // rather than rejecting an otherwise valid image.
    int? size;
    try {
      size = await picked.length();
    } catch (_) {
      size = null;
    }
    if (!mounted) return;
    setState(() {
      _pickedImage = picked;
      _pickedSize = size;
    });
  }

  /// Size class of the picked image against the service's advertised maximum
  /// (issue #008). `null` when nothing is picked or the size is unknown.
  FirmwareImageSizeStatus? _imageSizeStatus(FirmwareUiState ui) {
    final int? size = _pickedSize;
    if (size == null) return null;
    return classifyFirmwareImageSize(size, ui.info?.maxImageSize);
  }

  /// Asks the user to confirm a destructive firmware update (issue #008
  /// "Confirmation for destructive update"). Returns `true` only when the user
  /// explicitly taps "Confirm update"; cancel / dismiss / route pop = `false`.
  Future<bool> _confirmDestructiveUpdate(String action) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirm firmware update'),
        content: Text(
          '$action will reflash firmware on ${widget.systemId}. The system '
          'may be unavailable until the update completes, and this cannot be '
          'undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm update'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Reads the picked image bytes and pushes them via
  /// [FirmwareController.pushImage]; on success with a task-monitor URI,
  /// hands the update off to [FirmwareController.pollLastTask] — the
  /// controller's documented contract ("call [pollLastTask] after a
  /// successful upload when a task monitor URI was returned").
  Future<void> _pushUpload(FirmwareUiState ui) async {
    final XFile? file = _pickedImage;
    if (file == null || _isBusy(ui)) return;
    // Defense in depth: the Upload button is disabled above MaxImageSize, but
    // a stale UI snapshot must never push an oversized image either (#008).
    if (_imageSizeStatus(ui) == FirmwareImageSizeStatus.exceedsMaximum) return;
    if (!await _confirmDestructiveUpdate('Push upload')) return;
    if (!mounted) return;
    final FirmwareController controller =
        ref.read(firmwareControllerProvider(widget.systemId).notifier);
    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) return;
    await controller.pushImage(
      PushImageRequest(
        bytes: bytes,
        filename: file.name,
        // `null` = "Service default" — the request body omits
        // `@Redfish.OperationApplyTime` entirely (toUpdateParametersJson only
        // emits it when set), so the service applies its own current mode.
        applyTime: _applyTime,
      ),
    );
    if (!mounted) return;
    final FirmwareUiState after =
        ref.read(firmwareControllerProvider(widget.systemId));
    final UpdateTask? task = after.lastTask;
    if (after.error != null ||
        task == null ||
        task.taskUri == null ||
        task.taskUri!.isEmpty) {
      // Failed upload (the error card covers it) or 204-no-Location service:
      // the queued label covers the latter; do not poll nothing.
      return;
    }
    await controller.pollLastTask();
  }

  /// Submits a `SimpleUpdate` via [FirmwareController.startUpdate]; on success
  /// with a 202 task-monitor URI, hands the handle off to
  /// [FirmwareController.pollLastTask] so the task banner's live progress,
  /// `TaskState` badge and messages log advance after a Start (issue #008).
  ///
  /// Mirrors [_pushUpload]'s handoff: both destructive update paths converge
  /// on the same controller contract ("call [pollLastTask] after a successful
  /// update when a task monitor URI was returned"). A failed Start (error card
  /// covers it) or a 204-no-Location service (queued label covers it) has
  /// nothing to poll and is a no-op.
  Future<void> _startSimpleUpdate(FirmwareUiState ui) async {
    if (_isBusy(ui)) return;
    final String uri = _imageUriController.text.trim();
    if (uri.isEmpty) return;
    if (!await _confirmDestructiveUpdate('Simple update')) return;
    if (!mounted) return;
    final FirmwareController controller =
        ref.read(firmwareControllerProvider(widget.systemId).notifier);
    await controller.startUpdate(
      SimpleUpdateRequest(
        imageUri: uri,
        transferProtocol: _transferProtocol,
        targets: const <String>[],
      ),
    );
    if (!mounted) return;
    final FirmwareUiState after =
        ref.read(firmwareControllerProvider(widget.systemId));
    final UpdateTask? task = after.lastTask;
    if (after.error != null ||
        task == null ||
        task.taskUri == null ||
        task.taskUri!.isEmpty) {
      // Failed Start or 204-no-Location service: nothing to poll.
      return;
    }
    await controller.pollLastTask();
  }

  @override
  Widget build(BuildContext context) {
    final SystemHandle? handle =
        ref.watch(systemHandleProvider(widget.systemId));
    final SystemFeatures? features = handle?.features;

    // Discovery not complete yet (or tab shown before capability gate).
    // UI-2: announce a single merged "Loading firmware" node instead of a bare
    // unlabeled progress indicator (the established discovery-pending pattern).
    if (handle == null || features == null) {
      return Center(
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: 'Loading firmware',
          child: const CircularProgressIndicator(),
        ),
      );
    }
    // Hard gate: no firmware update capability → render nothing (no placeholder).
    if (!features.firmwareUpdate) {
      return const SizedBox.shrink();
    }

    final FirmwareUiState ui =
        ref.watch(firmwareControllerProvider(widget.systemId));
    final FirmwareController controller =
        ref.read(firmwareControllerProvider(widget.systemId).notifier);
    final List<String> protocols = ui.info?.transferProtocols ??
        const UpdateServiceInfo().transferProtocols;
    // Upload size gate (issue #008): classify the picked image against the
    // service's MaxImageSize (hard) and the 100 MiB soft threshold.
    final FirmwareImageSizeStatus? sizeStatus = _imageSizeStatus(ui);
    final bool sizeExceeds =
        sizeStatus == FirmwareImageSizeStatus.exceedsMaximum;
    final int? maxBytes = ui.info?.maxImageSize;
    final int? pickedSize = _pickedSize;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // UI-2: the header row announces as ONE merged semantics node
                // (title + in-flight spinner), same pattern as the
                // SystemCard/InfoCard/KVM/PowerView/HealthBanner headers. The
                // CircularProgressIndicator otherwise announces a bare
                // progress node next to the title.
                Semantics(
                  container: true,
                  excludeSemantics: true,
                  label: ui.loading
                      ? 'Firmware and update management, loading'
                      : 'Firmware and update management',
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Firmware & update management',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (ui.loading)
                        const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _ServiceSummary(info: ui.info),
                const SizedBox(height: 12),
                if (ui.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: <Widget>[
                            // UI-2: the icon + message announce as ONE node,
                            // so a screen reader gets the error in context
                            // instead of a bare detached sentence (the
                            // established OverviewView/SensorsView error-state
                            // pattern). The Retry button keeps its own node
                            // (it is a control).
                            Expanded(
                              child: Semantics(
                                container: true,
                                excludeSemantics: true,
                                label: 'Unable to load firmware. ${ui.error}',
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ui.error!,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Retry loading firmware inventory',
                              child: TextButton(
                                // WCAG 2.5.5 / Material 48x48dp minimum hit
                                // area on desktop, independent of the resolved
                                // materialTapTargetSize (#010).
                                style: accessibleTouchTargetStyle(),
                                onPressed:
                                    ui.loading ? null : () => controller.load(),
                                child: const Text('Retry'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                _InventoryList(info: ui.info),
                if (ui.uploading)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Semantics(
                              container: true,
                              excludeSemantics: true,
                              label: 'Uploading firmware image',
                              child: Row(
                                children: <Widget>[
                                  const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Uploading firmware image…',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (ui.uploadProgress != null) ...<Widget>[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ui.uploadProgress!.total == 0
                                      ? null
                                      : ui.uploadProgress!.sent /
                                          ui.uploadProgress!.total,
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${ui.uploadProgress!.sent} / '
                                '${ui.uploadProgress!.total} bytes',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                if (ui.lastTask != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Semantics(
                          container: true,
                          excludeSemantics: true,
                          label: _taskLabel(ui),
                          child: Row(
                            children: <Widget>[
                              if (ui.polling) ...<Widget>[
                                const SizedBox.square(
                                  dimension: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  _taskText(ui),
                                  style: TextStyle(
                                    color: ui.lastResult != null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              if (ui.lastResult != null &&
                                  ui.lastResult!.isSuccess)
                                const SizedBox(width: 8),
                              if (ui.lastResult != null &&
                                  ui.lastResult!.isSuccess)
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                        // Live/terminal TaskState badge (issue #008). The
                        // terminal result wins; while polling we show the
                        // monitor's last non-terminal state string.
                        if (_taskBadgeState(ui) != null) ...<Widget>[
                          const SizedBox(height: 6),
                          _TaskStateBadge(
                            state: _taskBadgeState(ui)!,
                            isSuccess: ui.lastResult?.isSuccess ?? false,
                            isFailed: ui.lastResult?.isFailed ?? false,
                          ),
                        ],
                        if (_taskCancellable(ui)) ...<Widget>[
                          const SizedBox(height: 2),
                          TextButton.icon(
                            onPressed: () => controller.cancelTask(),
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('Cancel update task'),
                          ),
                        ],
                        if (ui.cancelling && ui.lastResult == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Cancelling update task…'),
                          ),
                        // Normalized task Messages[] log (issue #008) — shown
                        // once the monitor reaches a terminal state with
                        // messages; wrapped so 320 px never overflows.
                        if (ui.lastResult != null &&
                            ui.lastResult!.messages.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          _TaskMessagesLog(messages: ui.lastResult!.messages),
                        ],
                      ],
                    ),
                  ),
                // Task-timeline progress (#008/#020): while the monitor is
                // being polled and the task published a `PercentComplete`
                // (absent on the pinned DMTF mockup — treated as unknown),
                // render a determinate bar + percentage so users see the
                // update advancing. Determinate value only — never an
                // indeterminate spinner here (the pumpAndSettle trap).
                if (ui.polling && ui.pollProgress != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Semantics(
                    container: true,
                    excludeSemantics: true,
                    label: 'Task progress',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (ui.pollProgress!.clamp(0, 100)) / 100,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ui.pollProgress!.clamp(0, 100)}% complete',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Start update',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _imageUriController,
                  decoration: const InputDecoration(
                    labelText: 'Image URI',
                    hintText: 'http://host/path/firmware.bin',
                  ),
                ),
                const SizedBox(height: 12),
                // UI-2: the protocol selector gets a visible + semantic label
                // ("Transfer protocol") — the bare DropdownButton previously
                // announced only its value with no field context (unlike the
                // Image URI TextField above, which carries a labelText), and
                // sighted users had no cue what the dropdown selected either.
                // The label is plain Text (its own semantics node, like the
                // TextField label), so the control keeps its own node and
                // screen readers hear "Transfer protocol" then the value.
                Text(
                  'Transfer protocol',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: _transferProtocol,
                  isExpanded: true,
                  items: <DropdownMenuItem<String>>[
                    for (final String p in protocols)
                      DropdownMenuItem<String>(
                        value: p,
                        child: Text(p),
                      ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _transferProtocol = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: ui.loading ? null : () => _startSimpleUpdate(ui),
                  icon: ui.starting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update),
                  label: Text(ui.starting ? 'Starting…' : 'Start'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Push upload (#008/#020 file-picker integration): only when the
        // service advertises a push URI (HttpPushUri / MultipartHttpPushUri).
        // Not advertised → no card, no placeholder (capability-gated).
        if (_pushAvailable(ui))
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Push upload',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  // UI-2: the selection state announces as ONE merged node
                  // ("No firmware image selected" / "Selected firmware
                  // image: <name>") — the established summary-row pattern
                  // (icon + text are decorative/context, not two bare nodes).
                  Semantics(
                    container: true,
                    excludeSemantics: true,
                    label: _pickedImage == null
                        ? 'No firmware image selected'
                        : 'Selected firmware image: ${_pickedImage!.name}',
                    child: Row(
                      children: <Widget>[
                        Icon(
                          _pickedImage == null
                              ? Icons.description_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pickedImage?.name ?? 'No file selected',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Size warnings (issue #008): above the service's
                  // MaxImageSize the Upload control is disabled and the image
                  // cannot be pushed; above the 100 MiB soft threshold it is
                  // still allowed but flagged as potentially slow. Each is a
                  // single merged semantics node so 320 px never overflows.
                  if (sizeStatus ==
                      FirmwareImageSizeStatus.exceedsMaximum) ...<Widget>[
                    const SizedBox(height: 6),
                    Semantics(
                      container: true,
                      excludeSemantics: true,
                      label: 'Image too large: '
                          '${formatFirmwareImageSize(pickedSize ?? 0)} exceeds '
                          'the maximum ${formatFirmwareImageSize(maxBytes ?? 0)}',
                      child: Text(
                        'Image (${formatFirmwareImageSize(pickedSize ?? 0)}) '
                        'exceeds the maximum '
                        '(${formatFirmwareImageSize(maxBytes ?? 0)}). '
                        'Choose a smaller image.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ] else if (sizeStatus ==
                      FirmwareImageSizeStatus.softWarning) ...<Widget>[
                    const SizedBox(height: 6),
                    Semantics(
                      container: true,
                      excludeSemantics: true,
                      label: 'Large image warning: '
                          '${formatFirmwareImageSize(pickedSize ?? 0)} may be '
                          'slow to upload',
                      child: Text(
                        'Large image (${formatFirmwareImageSize(pickedSize ?? 0)}) '
                        '— the upload may be slow over the BMC link.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Apply-time selection (#008/#020): only when the service
                  // advertises `HttpPushUriApplyTime.ApplyTime@
                  // Redfish.AllowableValues` — capability-gated, never an
                  // assumed set. Default is "Service default" (`null`): the
                  // request omits `@Redfish.OperationApplyTime` and the
                  // service applies its own current mode — the client must
                  // NOT assume Immediate.
                  if (_applyTimeOptions(ui).isNotEmpty) ...<Widget>[
                    Text(
                      'Apply time',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: _applyTime ?? _kServiceDefault,
                      isExpanded: true,
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem<String>(
                          value: _kServiceDefault,
                          child: Text('Service default'),
                        ),
                        for (final String mode in _applyTimeOptions(ui))
                          DropdownMenuItem<String>(
                            value: mode,
                            child: Text(mode),
                          ),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _applyTime =
                                value == _kServiceDefault ? null : value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Both controls disabled while a load or upload is in
                  // flight; Upload additionally requires a selection.
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: _isBusy(ui) ? null : () => _chooseImage(ui),
                        icon: const Icon(Icons.file_open),
                        label: const Text('Choose image…'),
                      ),
                      FilledButton.icon(
                        onPressed:
                            (_pickedImage == null || _isBusy(ui) || sizeExceeds)
                                ? null
                                : () => _pushUpload(ui),
                        icon: ui.uploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(ui.uploading ? 'Uploading…' : 'Upload'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Renders the UpdateService summary line (version + HTTP push URI).
class _ServiceSummary extends StatelessWidget {
  /// Creates a [_ServiceSummary].
  const _ServiceSummary({this.info});

  /// The loaded update-service info, or `null` before first load.
  final UpdateServiceInfo? info;

  @override
  Widget build(BuildContext context) {
    final UpdateServiceInfo? data = info;
    if (data == null) {
      // UI-2: no update-service data yet (in-flight or the fetch failed). Do
      // NOT render a dangling 'UpdateService ' label — the header row already
      // announces the in-flight state and, on failure, the error card is the
      // message.
      return const SizedBox.shrink();
    }
    final String? version = data.version;
    final String? httpPushUri = data.httpPushUri;
    final List<String> parts = <String>[
      if (version != null) version,
      if (httpPushUri != null) httpPushUri,
    ];
    // UI-2: the summary is ONE self-describing announcement (label + value
    // together) instead of a bare detached text node next to the merged
    // header row.
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          parts.isEmpty ? 'UpdateService' : 'UpdateService ${parts.join(', ')}',
      child: Text(
        parts.isEmpty ? 'UpdateService' : 'UpdateService ${parts.join(' · ')}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Human-readable queued/polled update text for the firmware banner.
///
/// Shows the task monitor URI from the 202 `Location` header and, when the
/// service sent a `Retry-After` delay (DSP0266 §12.2), the wait hint. While
/// [FirmwareUiState.polling] the text switches to the in-progress form;
/// once the monitor returns a terminal [FirmwareUiState.lastResult] it shows
/// the final task state instead.
String _taskText(FirmwareUiState ui) {
  final UpdateTask task = ui.lastTask!;
  final RedfishTask? result = ui.lastResult;
  if (result != null) {
    final String status = result.statusNote ?? result.state;
    return 'Update task ${result.id}: $status';
  }
  final String uri = task.taskUri == null || task.taskUri!.isEmpty
      ? '(no task URI returned)'
      : task.taskUri!;
  final String retry = task.retryAfterSeconds != null
      ? ' · retry after ${task.retryAfterSeconds}s'
      : '';
  if (ui.polling) {
    return 'Update in progress: polling $uri$retry';
  }
  return 'Update queued: $uri$retry';
}

/// Concise accessibility label for the queued/polled update banner (UI-2).
String _taskLabel(FirmwareUiState ui) {
  final UpdateTask task = ui.lastTask!;
  final RedfishTask? result = ui.lastResult;
  if (result != null) {
    final String status = result.statusNote ?? result.state;
    return 'Update task ${result.id}, $status';
  }
  final String uri = task.taskUri == null || task.taskUri!.isEmpty
      ? 'no task URI'
      : task.taskUri!;
  final String retry = task.retryAfterSeconds != null
      ? ', retry after ${task.retryAfterSeconds} seconds'
      : '';
  if (ui.polling) {
    return 'Update in progress, polling $uri$retry';
  }
  return 'Update queued, $uri$retry';
}

/// The TaskState string to show in the badge: the terminal result when the
/// task finished, otherwise the last in-flight monitor state (issue #008).
String? _taskBadgeState(FirmwareUiState ui) =>
    ui.lastResult?.state ?? ui.pollState;

/// A compact, colour-coded `TaskState` badge for the firmware task monitor
/// (issue #008). Success states use the primary container, failures the error
/// container, in-flight states the secondary container. The whole chip is one
/// merged semantics node so screen readers announce "Task state Running" in
/// context instead of a detached status word.
class _TaskStateBadge extends StatelessWidget {
  /// Creates a badge for [state].
  const _TaskStateBadge({
    required this.state,
    this.isSuccess = false,
    this.isFailed = false,
  });

  /// The `TaskState` value to display (`Completed`, `Running`, …).
  final String state;

  /// Whether a terminal task succeeded.
  final bool isSuccess;

  /// Whether a terminal task failed.
  final bool isFailed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = isSuccess
        ? colors.primaryContainer
        : isFailed
            ? colors.errorContainer
            : colors.secondaryContainer;
    final Color foreground = isSuccess
        ? colors.onPrimaryContainer
        : isFailed
            ? colors.onErrorContainer
            : colors.onSecondaryContainer;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'Task state $state',
      child: Chip(
        label: Text(state, style: TextStyle(color: foreground)),
        backgroundColor: background,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// The normalized `Messages[]` log of a terminal firmware task (issue #008).
///
/// Each entry prefers the human-readable `Message` and falls back to the
/// machine-readable `MessageId` when a service sends only the id. Long text
/// wraps rather than overflowing at 320 px.
class _TaskMessagesLog extends StatelessWidget {
  /// Creates a log for [messages].
  const _TaskMessagesLog({required this.messages});

  /// Terminal task messages, in the order the BMC published them.
  final List<TaskMessage> messages;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          container: true,
          excludeSemantics: true,
          label: 'Task messages: '
              '${messages.map((TaskMessage m) => m.message ?? m.messageId).join('; ')}',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Task messages', style: theme.textTheme.titleSmall),
                for (final TaskMessage m in messages)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '• ${m.message ?? m.messageId}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders the firmware inventory cards for a [FirmwareUiState.info].
class _InventoryList extends StatelessWidget {
  /// Creates an [_InventoryList].
  const _InventoryList({this.info});

  /// The loaded update-service info, or `null` before first load.
  final UpdateServiceInfo? info;

  @override
  Widget build(BuildContext context) {
    if (info == null) {
      // UI-2: the in-flight inventory load announces as ONE merged semantics
      // node ('Loading firmware inventory') instead of a bare detached text
      // node next to the header — the established loading-state pattern
      // (header row merges its own spinner; this announces the specific
      // surface that is still loading).
      return Semantics(
        container: true,
        excludeSemantics: true,
        label: 'Loading firmware inventory',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Text('Loading inventory…')),
        ),
      );
    }
    final UpdateServiceInfo data = info!;
    if (data.inventory.isEmpty) {
      // UI-2: a successful load with zero inventory renders the established
      // empty-state pattern — one self-describing merged semantics node (icon
      // + visible text), matching the Dashboard/KVM/Sensors empty states. No
      // Retry: the load succeeded, there is nothing to retry.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            container: true,
            excludeSemantics: true,
            label: 'No firmware inventory reported.',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.inventory_2_outlined,
                    size: 40, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  'No firmware inventory reported.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final FirmwareInventoryItem item in data.inventory)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              container: true,
              excludeSemantics: true,
              label: 'Firmware ${item.name ?? item.id}, '
                  '${item.version ?? 'version unknown'}, '
                  '${item.health ?? 'health unknown'}, '
                  '${item.updateable ? 'updateable' : 'locked'}',
              child: Card(
                child: ListTile(
                  title: Text(item.name ?? item.id),
                  subtitle: Text(
                    '${item.id}${item.version != null ? ' · ${item.version}' : ''}'
                    '${item.health != null ? ' · ${item.health}' : ''}',
                  ),
                  trailing: Chip(
                    label: Text(item.updateable ? 'Updateable' : 'Locked'),
                    backgroundColor: item.updateable
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.secondaryContainer,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
