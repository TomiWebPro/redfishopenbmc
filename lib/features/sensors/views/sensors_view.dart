import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redfishopenbmc/core/theme/accessible_buttons.dart';
import 'package:redfishopenbmc/features/sensors/models/polling_policy.dart';
import 'package:redfishopenbmc/features/sensors/models/reading_history.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/models/tile_fingerprint.dart';
import 'package:redfishopenbmc/features/sensors/sensors_controller.dart';
import 'package:redfishopenbmc/features/sensors/sensors_providers.dart';
import 'package:redfishopenbmc/features/sensors/views/sensor_chart.dart';
import 'package:redfishopenbmc/features/sensors/views/sensor_delta_tile.dart';
import 'package:redfishopenbmc/features/sensors/views/sensor_telemetry_widgets.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Sensor monitoring screen for a single system (issue #007).
///
/// Rendered only when the system advertises sensor monitoring
/// ([SystemFeatures.sensorMonitoring] is `true`); the [SystemShell] already
/// hides the tab otherwise, and this view additionally renders nothing when the
/// capability is absent so there is never a placeholder. Surfaces per-chassis
/// temperature, fan, voltage, and generic sensor readings pulled by
/// [SensorsController].
class SensorsView extends ConsumerStatefulWidget {
  /// Creates a [SensorsView] for [systemId].
  const SensorsView({
    required this.systemId,
    this.autoRefreshInterval = const Duration(seconds: 10),
    super.key,
  });

  /// Logical id of the system this view is scoped to.
  final String systemId;

  /// Periodic telemetry refresh interval, or `null` to disable auto-refresh.
  ///
  /// Defaults to 10 seconds to satisfy the real-time refresh acceptance in
  /// issue #019 while keeping load bounded by controller in-flight guarding.
  final Duration? autoRefreshInterval;

  @override
  ConsumerState<SensorsView> createState() => _SensorsViewState();
}

class _SensorsViewState extends ConsumerState<SensorsView>
    with WidgetsBindingObserver {
  ProviderSubscription<SystemHandle?>? _handleSubscription;
  late SensorsPollingScheduler _polling;
  bool _hadClient = false;
  bool _hidden = false;
  // #007 "Charts" box: charts are built on demand only — the default tile view
  // never pays for a LineChart. Switching modes is a local UI concern, so no
  // controller/provider change is needed.
  bool _showCharts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final SystemHandle? initial =
        ref.read(systemHandleProvider(widget.systemId));
    _hadClient = initial?.client != null;
    _handleSubscription = ref.listenManual<SystemHandle?>(
      systemHandleProvider(widget.systemId),
      (SystemHandle? prev, SystemHandle? next) {
        final bool hasClient = next?.client != null;
        if (hasClient && !_hadClient) {
          _load();
        }
        _hadClient = hasClient;
      },
    );
    _polling = _makePollingScheduler();
    if (widget.autoRefreshInterval != null) _polling.start();
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // #007: back off to the slower 30s cadence while the app is not visible,
    // and resume the fast cadence when it becomes visible again.
    final bool hidden = isSensorAppBackgrounded(state);
    if (hidden != _hidden) {
      _hidden = hidden;
      _polling.setHidden(hidden);
    }
  }

  @override
  void didUpdateWidget(covariant SensorsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.systemId != widget.systemId ||
        oldWidget.autoRefreshInterval != widget.autoRefreshInterval) {
      _startAutoRefresh();
      _load();
    }
  }

  SensorsPollingScheduler _makePollingScheduler() {
    final SensorsPollingScheduler scheduler = SensorsPollingScheduler(
      policy: SensorsPollingPolicy(
        visibleInterval:
            widget.autoRefreshInterval ?? const Duration(seconds: 10),
      ),
      onTick: _load,
    );
    if (_hidden) scheduler.setHidden(true);
    return scheduler;
  }

  void _startAutoRefresh() {
    _polling.stop();
    _polling = _makePollingScheduler();
    if (widget.autoRefreshInterval != null) _polling.start();
  }

  void _load() {
    Future<void>.microtask(
      () =>
          ref.read(sensorsControllerProvider(widget.systemId).notifier).load(),
    );
  }

  /// Pull-to-refresh handler: await the fetch so the indicator stays visible
  /// until it completes (the controller guards overlapping loads).
  Future<void> _refresh() async {
    await ref.read(sensorsControllerProvider(widget.systemId).notifier).load();
  }

  /// Switches between the tile list and the on-demand `fl_chart` trend list.
  void _setShowCharts(bool value) {
    if (value != _showCharts) setState(() => _showCharts = value);
  }

  @override
  void dispose() {
    _polling.stop();
    WidgetsBinding.instance.removeObserver(this);
    _handleSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SystemHandle? handle =
        ref.watch(systemHandleProvider(widget.systemId));
    final SystemFeatures? features = handle?.features;

    // Discovery not complete yet (or tab shown before capability gate).
    // Established UI-2 pattern: one merged, self-describing announcement (no
    // Retry — the system id does not exist, there is nothing to reload).
    if (handle == null) {
      return Center(
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: 'System not found',
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.search_off_outlined, size: 40),
              SizedBox(height: 8),
              Text('System not found'),
            ],
          ),
        ),
      );
    }
    // UI-2: discovery is still resolving capabilities for this system; announce
    // a single merged "Loading sensors" node (no Retry — nothing to reload yet)
    // instead of a bare unlabeled progress indicator.
    if (features == null) {
      return Center(
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: 'Loading sensors',
          child: const CircularProgressIndicator(),
        ),
      );
    }
    // Hard gate: no sensor monitoring → render nothing (no placeholder).
    if (!features.sensorMonitoring) {
      return const SizedBox.shrink();
    }

    final SensorsUiState ui =
        ref.watch(sensorsControllerProvider(widget.systemId));

    if (ui.loading) {
      // UI-2: the in-flight sensor load announces as ONE merged semantics
      // node ('Loading sensors') instead of a bare unlabeled progress
      // indicator — the established loading-state pattern (FirmwareView
      // header/inventory). The visible spinner stays for sighted users.
      return Center(
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: 'Loading sensors',
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (ui.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // UI-2: the icon + title + detail announce as ONE node, so a
              // screen reader gets the error in context instead of a bare
              // detached sentence (the established error-state pattern). The
              // Retry button keeps its own node (it is a control).
              Semantics(
                container: true,
                excludeSemantics: true,
                label: 'Unable to load sensors. ${ui.error}',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.cloud_off_outlined,
                        size: 40, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load sensors',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ui.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Tooltip(
                message: 'Retry loading sensors',
                child: FilledButton.icon(
                  // WCAG 2.5.5 / Material 48x48dp minimum hit area on desktop,
                  // independent of the resolved materialTapTargetSize (#010).
                  style: accessibleTouchTargetStyle(),
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (ui.chassis.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            container: true,
            excludeSemantics: true,
            label: 'No sensor data available',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.sensors_off_outlined,
                    size: 40, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  'No sensor data available',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // #007: combine all health/threshold breaches across visible chassis into
    // one banner at the top of the list (no banner when everything is nominal).
    final List<SensorAlert> alerts = <SensorAlert>[
      for (final ChassisSensors chassis in ui.chassis) ...chassis.alerts,
    ];

    // #007 acceptance: pull-to-refresh + last-updated timestamp. The list is
    // always scrollable so the RefreshIndicator can be dragged even when there
    // are few tiles; the stamp is capability/data driven (omitted until the
    // first successful poll) and announces as one merged semantics node.
    // #007 "Charts" box: only series with at least two samples can draw a
    // trend. Charts are laid out with ListView.builder so off-screen charts are
    // not built (viewport-lazy) and each one is inside a RepaintBoundary.
    final List<MapEntry<String, List<double>>> chartSeries =
        <MapEntry<String, List<double>>>[
      for (final MapEntry<String, List<double>> entry in ui.history.entries)
        if (entry.value.length >= 2) entry,
    ];
    final Widget header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (ui.lastUpdated != null) _LastUpdated(timestamp: ui.lastUpdated!),
        if (alerts.isNotEmpty) _AlertBanner(alerts: alerts),
        _ViewModeToggle(charts: _showCharts, onChanged: _setShowCharts),
        if (_showCharts && chartSeries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Collecting history…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );

    return RefreshIndicator(
      onRefresh: _refresh,
      child: _showCharts
          ? ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: 1 + chartSeries.length,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) return header;
                final MapEntry<String, List<double>> entry =
                    chartSeries[index - 1];
                return SensorLineChart(
                  title: chartTitleForKey(entry.key),
                  unit: chartUnitForKey(entry.key),
                  series: entry.value,
                );
              },
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                header,
                for (final ChassisSensors chassis in ui.chassis)
                  _ChassisCard(chassis: chassis, history: ui.history),
              ],
            ),
    );
  }
}

/// Tiles/Charts mode switch placed at the top of the telemetry list (#007).
///
/// Uses the existing Material [SegmentedButton] so it inherits the app theme;
/// "Charts" is always available — before two polls it simply shows a
/// "Collecting history…" caption rather than an empty placeholder tab.
class _ViewModeToggle extends StatelessWidget {
  /// Creates the view-mode switch.
  const _ViewModeToggle({required this.charts, required this.onChanged});

  /// Whether the chart list (rather than the tile list) is showing.
  final bool charts;

  /// Called with the newly selected mode.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SegmentedButton<bool>(
        // #010 a11y: guarantee a >=48dp hit area on desktop targets, where the
        // default Material segment collapses to 40dp (below WCAG 2.5.5).
        style: accessibleTouchTargetStyle(),
        showSelectedIcon: false,
        segments: const <ButtonSegment<bool>>[
          ButtonSegment<bool>(
            value: false,
            label: Text('Tiles'),
            icon: Icon(Icons.grid_view_outlined),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text('Charts'),
            icon: Icon(Icons.show_chart),
          ),
        ],
        selected: <bool>{charts},
        onSelectionChanged: (Set<bool> selection) => onChanged(selection.first),
      ),
    );
  }
}

/// Formats the "last updated" wall-clock stamp as `HH:MM:SS` (local time).
///
/// Pure + locale-independent so it can be pinned in a unit test without an
/// `intl` dependency or a real clock.
String formatSensorLastUpdated(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}

/// A single merged "Last updated HH:MM:SS" line above the telemetry list
/// (issue #007 acceptance). Shown only after the first successful poll.
class _LastUpdated extends StatelessWidget {
  /// Creates a [_LastUpdated] line.
  const _LastUpdated({required this.timestamp});

  /// The wall-clock time of the last successful telemetry poll.
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    final String label = 'Last updated ${formatSensorLastUpdated(timestamp)}';
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: <Widget>[
            Icon(Icons.schedule,
                size: 16, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single chassis card grouping its temperatures, fans, voltages, and sensors.
class _ChassisCard extends StatelessWidget {
  /// Creates a [_ChassisCard].
  const _ChassisCard({required this.chassis, required this.history});

  /// The telemetry for one chassis.
  final ChassisSensors chassis;

  /// Per-sensor recent-reading series (key → oldest-first samples).
  final Map<String, List<double>> history;

  @override
  Widget build(BuildContext context) {
    final String title = chassis.chassisName ?? chassis.chassisId;
    final String summaryLabel =
        'Chassis ${chassis.chassisId}, ${chassis.thermal.length} '
        'temperatures, ${chassis.fans.length} fans, '
        '${chassis.voltages.length} voltages, '
        '${chassis.sensors.length} sensors';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              container: true,
              excludeSemantics: true,
              label: summaryLabel,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            if (chassis.thermal.isNotEmpty) ...<Widget>[
              // UI-2: section headers announce as one self-describing node
              // (title + count), same merged pattern as the card headers —
              // the counts are context a sighted user gets visually.
              Semantics(
                container: true,
                excludeSemantics: true,
                label: 'Temperatures, ${chassis.thermal.length}',
                child: Text('Temperatures',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: 4),
              for (final ThermalReading t in chassis.thermal)
                SensorDeltaTile(
                  fingerprint: temperatureTileFingerprint(t),
                  builder: (_) => _TemperatureTile(
                    t,
                    series:
                        history[thermalSeriesKey(chassis.chassisId, t.name)] ??
                            const <double>[],
                  ),
                ),
              const SizedBox(height: 12),
            ],
            if (chassis.fans.isNotEmpty) ...<Widget>[
              Semantics(
                container: true,
                excludeSemantics: true,
                label: 'Fans, ${chassis.fans.length}',
                child:
                    Text('Fans', style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: 4),
              for (final FanReading f in chassis.fans)
                SensorDeltaTile(
                  fingerprint: fanTileFingerprint(f),
                  builder: (_) => _FanTile(
                    f,
                    series: history[fanSeriesKey(chassis.chassisId, f.name)] ??
                        const <double>[],
                  ),
                ),
              const SizedBox(height: 12),
            ],
            if (chassis.voltages.isNotEmpty) ...<Widget>[
              // #007: OpenBMC `Thermal.Voltages[]` normalized into the same
              // telemetry picture — rendered only when the BMC reports any.
              Semantics(
                container: true,
                excludeSemantics: true,
                label: 'Voltages, ${chassis.voltages.length}',
                child: Text('Voltages',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: 4),
              for (final VoltageReading v in chassis.voltages)
                SensorDeltaTile(
                  fingerprint: voltageTileFingerprint(v),
                  builder: (_) => _VoltageTile(
                    v,
                    series:
                        history[voltageSeriesKey(chassis.chassisId, v.name)] ??
                            const <double>[],
                  ),
                ),
              const SizedBox(height: 12),
            ],
            if (chassis.sensors.isNotEmpty) ...<Widget>[
              Semantics(
                container: true,
                excludeSemantics: true,
                label: 'Sensors, ${chassis.sensors.length}',
                child: Text('Sensors',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: 4),
              for (final SensorReading s in chassis.sensors)
                SensorDeltaTile(
                  fingerprint: sensorTileFingerprint(s),
                  builder: (_) => _SensorTile(
                    s,
                    series:
                        history[sensorSeriesKey(chassis.chassisId, s.name)] ??
                            const <double>[],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A temperature reading row with health tint, threshold hint and trend.
class _TemperatureTile extends StatelessWidget {
  /// Creates a [_TemperatureTile].
  const _TemperatureTile(this.reading, {required this.series});

  /// The temperature reading to render.
  final ThermalReading reading;

  /// Recent readings for this sensor (oldest first).
  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final String value = reading.readingCelsius == null
        ? '—'
        : '${reading.readingCelsius!.toStringAsFixed(1)}°C';
    final List<String> thresholds = <String>[
      if (reading.upperCaution != null)
        'caution ${reading.upperCaution!.toStringAsFixed(0)}',
      if (reading.upperCritical != null)
        'crit ${reading.upperCritical!.toStringAsFixed(0)}',
    ];
    final bool hasThreshold = reading.lowerCritical != null ||
        reading.lowerCaution != null ||
        reading.upperCaution != null ||
        reading.upperCritical != null;
    // UI-2: the merged label carries the same threshold context sighted users
    // get from the subtitle (the tile is one self-describing announcement —
    // `excludeSemantics` drops the inner Text, so the label must include it).
    final String announced =
        'Temperature ${reading.name}, $value, ${_healthLabel(reading.status.healthEnum)}'
        '${thresholds.isEmpty ? '' : ', ${thresholds.join(' / ')}'}';
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: announced,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(reading.name),
            subtitle:
                thresholds.isNotEmpty ? Text(thresholds.join(' / ')) : null,
            trailing:
                _HealthChip(displayLevel: reading.displayLevel, label: value),
          ),
          if (series.length >= 2 || hasThreshold)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  SensorSparkline(values: series),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ThresholdBar(
                      value: reading.readingCelsius,
                      lowerCritical: reading.lowerCritical,
                      lowerCaution: reading.lowerCaution,
                      upperCaution: reading.upperCaution,
                      upperCritical: reading.upperCritical,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A fan reading row with physical context and trend.
class _FanTile extends StatelessWidget {
  /// Creates a [_FanTile].
  const _FanTile(this.reading, {required this.series});

  /// The fan reading to render.
  final FanReading reading;

  /// Recent readings for this sensor (oldest first).
  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final String value = reading.reading == null
        ? '—'
        : '${reading.reading!.toStringAsFixed(0)} RPM';
    // UI-2: the merged label carries the physical-context hint sighted users
    // get from the subtitle (one self-describing announcement; the inner
    // subtitle Text is excluded from semantics, so the label must keep it).
    final String announced =
        'Fan ${reading.name}, $value, ${_healthLabel(reading.status.healthEnum)}'
        '${reading.physicalContext == null ? '' : ', ${reading.physicalContext}'}';
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: announced,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(reading.name),
            subtitle: reading.physicalContext != null
                ? Text(reading.physicalContext!)
                : null,
            trailing:
                _HealthChip(displayLevel: reading.displayLevel, label: value),
          ),
          if (series.length >= 2 || reading.upperCritical != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  SensorSparkline(values: series),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ThresholdBar(
                      value: reading.reading,
                      upperCritical: reading.upperCritical,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A voltage reading row with health tint, threshold hint and trend (issue #007).
class _VoltageTile extends StatelessWidget {
  /// Creates a [_VoltageTile].
  const _VoltageTile(this.reading, {required this.series});

  /// The voltage reading to render.
  final VoltageReading reading;

  /// Recent readings for this sensor (oldest first).
  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final String value = reading.readingVolts == null
        ? '—'
        : '${reading.readingVolts!.toStringAsFixed(2)} V';
    final List<String> thresholds = <String>[
      if (reading.lowerCaution != null)
        'low ${reading.lowerCaution!.toStringAsFixed(1)}',
      if (reading.upperCaution != null)
        'caution ${reading.upperCaution!.toStringAsFixed(1)}',
      if (reading.upperCritical != null)
        'crit ${reading.upperCritical!.toStringAsFixed(1)}',
    ];
    final bool hasThreshold = reading.lowerCritical != null ||
        reading.lowerCaution != null ||
        reading.upperCaution != null ||
        reading.upperCritical != null;
    // UI-2: one self-describing node carries the physical-context + threshold
    // hints sighted users get from the subtitle (excludeSemantics drops the
    // inner Text, so the merged label must keep them).
    final String announced =
        'Voltage ${reading.name}, $value, ${_healthLabel(reading.status.healthEnum)}'
        '${reading.physicalContext == null ? '' : ', ${reading.physicalContext}'}'
        '${thresholds.isEmpty ? '' : ', ${thresholds.join(' / ')}'}';
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: announced,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(reading.name),
            subtitle: Text(<String>[
              if (reading.physicalContext != null) reading.physicalContext!,
              if (thresholds.isNotEmpty) thresholds.join(' / '),
            ].join(' · ')),
            trailing:
                _HealthChip(displayLevel: reading.displayLevel, label: value),
          ),
          if (series.length >= 2 || hasThreshold)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  SensorSparkline(values: series),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ThresholdBar(
                      value: reading.readingVolts,
                      lowerCritical: reading.lowerCritical,
                      lowerCaution: reading.lowerCaution,
                      upperCaution: reading.upperCaution,
                      upperCritical: reading.upperCritical,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A generic sensor reading row with type, thresholds and trend.
class _SensorTile extends StatelessWidget {
  /// Creates a [_SensorTile].
  const _SensorTile(this.reading, {required this.series});

  /// The sensor reading to render.
  final SensorReading reading;

  /// Recent readings for this sensor (oldest first).
  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final String value = reading.reading == null
        ? '—'
        : '${reading.reading!.toStringAsFixed(2)} ${reading.readingUnits ?? ''}'
            .trim();
    final List<String> thresholds = reading.thresholds.entries
        .map((MapEntry<String, double> e) =>
            '${e.key} ${e.value.toStringAsFixed(1)}')
        .toList();
    // UI-2: the merged label carries the reading-type + threshold context
    // sighted users get from the subtitle (one self-describing announcement;
    // the inner subtitle Text is excluded from semantics, so the label must
    // keep it).
    final String announced =
        'Sensor ${reading.name}, $value, ${_healthLabel(reading.status.healthEnum)}'
        '${reading.readingType == null ? '' : ', ${reading.readingType}'}'
        '${thresholds.isEmpty ? '' : ', ${thresholds.join(' / ')}'}';
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: announced,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(reading.name),
            subtitle: Text(<String>[
              if (reading.readingType != null) reading.readingType!,
              if (thresholds.isNotEmpty) thresholds.join(' / '),
            ].join(' · ')),
            trailing:
                _HealthChip(displayLevel: reading.displayLevel, label: value),
          ),
          if (series.length >= 2 || reading.thresholds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  SensorSparkline(values: series),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ThresholdBar(
                      value: reading.reading,
                      lowerCritical: reading.thresholds['LowerCritical'],
                      lowerCaution: reading.thresholds['LowerCaution'],
                      upperCaution: reading.thresholds['UpperCaution'],
                      upperCritical: reading.thresholds['UpperCritical'],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Human-readable health label used in merged accessibility summaries
/// (matches the dashboard `HealthBanner` wording — UI-2).
String _healthLabel(Health health) => switch (health) {
      Health.ok => 'OK',
      Health.warning => 'Warning',
      Health.critical => 'Critical',
      Health.unknown => 'Unknown',
    };

/// Chip colour for a sensor's [SensorDisplayLevel] (issue #007 "Threshold
/// coloring"). Pure + dependency-free so the OK / Warning / Critical / no-reading
/// mapping can be pinned in a unit test; the visible chip uses it for both its
/// border and its tinted background.
Color sensorDisplayLevelColor(SensorDisplayLevel level) => switch (level) {
      SensorDisplayLevel.none => Colors.grey,
      SensorDisplayLevel.ok => Colors.green,
      SensorDisplayLevel.warning => Colors.orange,
      SensorDisplayLevel.critical => Colors.red,
    };

/// A compact health-tinted chip showing a reading value.
class _HealthChip extends StatelessWidget {
  /// Creates a [_HealthChip].
  const _HealthChip({required this.displayLevel, required this.label});

  /// Display severity used to pick the chip color (health + threshold breach +
  /// reading presence — issue #007).
  final SensorDisplayLevel displayLevel;

  /// The reading value rendered inside the chip.
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color = sensorDisplayLevelColor(displayLevel);
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Banner summarising all health/threshold alerts across the visible chassis
/// (issue #007).
///
/// Shown only when at least one reading reports Warning/Critical health or
/// breaches a critical/caution threshold. Per-tile chips now tint from the
/// combined [SensorDisplayLevel] too (health + breach + reading presence), so
/// the banner is the aggregated view of every breach across all chassis, while
/// the chip localises the severity to its own reading.
class _AlertBanner extends StatelessWidget {
  /// Creates an [_AlertBanner].
  const _AlertBanner({required this.alerts});

  /// The alerts to summarise (non-empty by convention).
  final List<SensorAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final bool anyCritical =
        alerts.any((SensorAlert a) => a.level == SensorAlertLevel.critical);
    final Color color =
        anyCritical ? Theme.of(context).colorScheme.error : Colors.deepOrange;
    final String label = 'Sensor alert${alerts.length == 1 ? '' : 's'}: '
        '${alerts.map((SensorAlert a) => a.description).join('; ')}';
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      child: Card(
        color: color.withValues(alpha: 0.10),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                anyCritical
                    ? Icons.error_outline
                    : Icons.warning_amber_outlined,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      anyCritical ? 'Critical sensor alert' : 'Sensor warning',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: color),
                    ),
                    const SizedBox(height: 4),
                    for (final SensorAlert alert in alerts)
                      Text(
                        alert.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
