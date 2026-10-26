import 'dart:convert';

/// A Redfish `Task` resource, parsed for the task-monitor polling path.
///
/// Mirrors the served `#Task.v1_7_3.Task` shape (and the newest
/// `Task.v1_7_4.json`) the client reads when following the 202 `Location`
/// task-monitor URI a Redfish service returns from an asynchronous action
/// (DSP0266 §12.2 "Asynchronous operations"; `Task.v1_7_4.json` mirrored
/// as DOCS-10, served version `v1_7_3` mirrored as DOCS-13).
///
/// A poller GETs the task monitor, parses this, and decides from
/// [TaskState] whether the task is still running ([isTerminal]) and whether
/// it succeeded ([isSuccess]). [PercentComplete] is optional on the schema
/// (`type: ['integer','null']`, 0–100) — many BMCs never publish it, so the
/// model tolerates absence (progress stays "unknown").
class RedfishTask {
  /// Creates a [RedfishTask].
  const RedfishTask({
    required this.id,
    this.name,
    required this.state,
    this.status,
    this.percentComplete,
    this.startTime,
    this.endTime,
    this.messages = const <TaskMessage>[],
    this.taskMonitorUri,
  });

  /// Task resource id (`Id`, e.g. `545`).
  final String id;

  /// Human-readable task name (`Name`), or `null` when absent.
  final String? name;

  /// Current `TaskState` (13 values per `Task.v1_7_4.json`).
  final String state;

  /// `TaskStatus` (`OK` / `Warning` / `Critical`), or `null` when absent.
  final String? status;

  /// Completion percentage 0–100, or `null` when the service never published
  /// it (the common case on the pinned DMTF mockup — the poller must treat
  /// a missing value as unknown, never throw).
  final int? percentComplete;

  /// `StartTime` (RFC3339), parsed when present.
  final DateTime? startTime;

  /// `EndTime` (RFC3339), parsed when present.
  final DateTime? endTime;

  /// Messages attached to the task (`MessageId` / `Message` / `MessageArgs` /
  /// `Severity`) — the normalized task-error surface.
  final List<TaskMessage> messages;

  /// `TaskMonitor` URI the schema documents for the task monitor
  /// (`TaskMonitor`, added v1_2_0), when the resource publishes it.
  final String? taskMonitorUri;

  /// States that mean the task is finished (no more progress will happen).
  ///
  /// Per `Task.v1_7_4.json` TaskState enum: `Completed` (success or failure
  /// depending on [status]), `Killed` / `Exception` / `Service` / `Cancelled`
  /// (terminal failures). Everything else (`New`, `Starting`, `Running`,
  /// `Suspended`, `Interrupted`, `Pending`, `Stopping`, `Cancelling`) is
  /// still in flight.
  static const Set<String> _terminalStates = <String>{
    'Completed',
    'Killed',
    'Exception',
    'Service',
    'Cancelled',
  };

  /// States that are a definitive failure regardless of [status].
  static const Set<String> _failureStates = <String>{
    'Killed',
    'Exception',
    'Service',
    'Cancelled',
  };

  /// Whether the task has reached a terminal [TaskState].
  bool get isTerminal => _terminalStates.contains(state);

  /// Whether the task finished successfully.
  ///
  /// A `Completed` task is success when its [status] is `OK` — or absent
  /// (the served mockup task carries no TaskStatus edge; a bare `Completed`
  /// with no status is treated as success). `Completed` with a
  /// `Warning`/`Critical` status is *not* clean success (see
  /// [statusNote]).
  bool get isSuccess =>
      state == 'Completed' && (status == null || status == 'OK');

  /// Whether the task ended in a terminal failure state.
  ///
  /// A task is failed when it reached a definitive failure [TaskState], or
  /// when it `Completed` with a non-OK [status] (`Warning`/`Critical`).
  bool get isFailed =>
      _failureStates.contains(state) ||
      (state == 'Completed' && status != null && status != 'OK');

  /// A human-readable reason when the task failed, or `null` when it is
  /// still running or succeeded.
  ///
  /// Prefers the first task `Message.Message`, then the first `MessageId`,
  /// then falls back to the bare `TaskState` (e.g. `Killed`).
  String? get failureReason {
    if (!isFailed) return null;
    for (final TaskMessage m in messages) {
      if (m.message != null && m.message!.isNotEmpty) return m.message;
    }
    for (final TaskMessage m in messages) {
      if (m.messageId.isNotEmpty) return m.messageId;
    }
    return 'Task $state';
  }

  /// A short note appended for a `Completed` task with a non-OK status
  /// (e.g. `Completed with status Warning`), or `null` when clean.
  String? get statusNote {
    if (state != 'Completed' || status == null || status == 'OK') return null;
    return 'Completed with $status';
  }

  /// Builds a [RedfishTask] from a `Task` resource body.
  ///
  /// Tolerates absent optional fields (the mockup-served 545 has no
  /// `PercentComplete`); an RFC3339-unparseable `StartTime`/`EndTime` is
  /// kept as `null` rather than failing the parse.
  factory RedfishTask.fromJson(Map<String, dynamic> body) {
    final String? odataId = _asString(body['@odata.id']);
    final String derivedId = _asString(body['Id']) ??
        odataId?.split('/').where((String s) => s.isNotEmpty).last ??
        '';

    final List<TaskMessage> messages = <TaskMessage>[];
    final dynamic rawMessages = body['Messages'];
    if (rawMessages is List<dynamic>) {
      for (final dynamic raw in rawMessages) {
        if (raw is Map<dynamic, dynamic>) {
          messages.add(TaskMessage.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return RedfishTask(
      id: derivedId,
      name: _asString(body['Name']),
      state: _asString(body['TaskState']) ?? 'Unknown',
      status: _asString(body['TaskStatus']),
      percentComplete: body['PercentComplete'] is num
          ? (body['PercentComplete'] as num).toInt()
          : null,
      startTime: _parseTime(body['StartTime']),
      endTime: _parseTime(body['EndTime']),
      messages: messages,
      taskMonitorUri: _asString(body['TaskMonitor']),
    );
  }

  @override
  String toString() => 'RedfishTask($id: state=$state, status=$status, '
      'percentComplete=$percentComplete, messages=${messages.length})';

  /// Convenience JSON decode + parse used by the model tests.
  static RedfishTask fromJsonString(String source) =>
      RedfishTask.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

/// One entry of a `Task.Messages[]` array.
///
/// Mirrors the `Message` definition (`MessageId` / `Message` /
/// `MessageArgs` / `Severity`) the task resource reuses from
/// `Message.json#/definitions/Message` — the same shape
/// `@Message.ExtendedInfo` builds on (issue #014).
class TaskMessage {
  /// Creates a [TaskMessage].
  const TaskMessage({
    required this.messageId,
    this.message,
    this.messageArgs = const <String>[],
    this.severity,
    this.relatedProperties = const <String>[],
  });

  /// Machine-readable message id (e.g. `Base.1.0.PropertyNotWritable`).
  final String messageId;

  /// Human-readable message text, or `null` when only the id is present.
  final String? message;

  /// Message-format arguments substituted into the message template.
  final List<String> messageArgs;

  /// Message severity (`OK` / `Warning` / `Critical`), or `null`.
  final String? severity;

  /// `RelatedProperties` the message applies to, when present.
  final List<String> relatedProperties;

  /// Builds a [TaskMessage] from a raw message body (map form).
  factory TaskMessage.fromJson(Map<String, dynamic> body) {
    final List<String> args = <String>[];
    final dynamic rawArgs = body['MessageArgs'];
    if (rawArgs is List<dynamic>) {
      for (final dynamic arg in rawArgs) {
        if (arg is String) args.add(arg);
      }
    }
    final List<String> related = <String>[];
    final dynamic rawRelated = body['RelatedProperties'];
    if (rawRelated is List<dynamic>) {
      for (final dynamic r in rawRelated) {
        if (r is String) related.add(r);
      }
    }
    return TaskMessage(
      messageId: _asString(body['MessageId']) ?? _asString(body['Id']) ?? '',
      message: _asString(body['Message']),
      messageArgs: args,
      severity: _asString(body['Severity']),
      relatedProperties: related,
    );
  }

  @override
  String toString() => 'TaskMessage($messageId: $message, severity=$severity)';
}

/// Returns [value] as a [String] or `null` when it is not a string.
String? _asString(Object? value) => value is String ? value : null;

/// Parses an RFC3339-ish timestamp into a [DateTime], or returns `null`
/// when the value is absent/unparseable.
DateTime? _parseTime(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}
