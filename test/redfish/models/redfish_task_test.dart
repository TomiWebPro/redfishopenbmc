import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/redfish/models/redfish_task.dart';

/// Unit tests for the [RedfishTask] task-monitor model and the
/// [TaskMessage] message parse (issue #022 criterion 1 — 202 task-monitor
/// polling, folding into #008/#020; `Task.v1_7_4.json` enum, served
/// `Task.v1_7_3.json` fixture shape).
void main() {
  group('RedfishTask.fromJson', () {
    test('parses a full task payload (mockup 545 shape)', () {
      final RedfishTask task = RedfishTask.fromJson(<String, dynamic>{
        '@odata.type': '#Task.v1_7_3.Task',
        '@odata.id': '/redfish/v1/TaskService/Tasks/545',
        'Id': '545',
        'Name': 'Task 545',
        'TaskState': 'Completed',
        'TaskStatus': 'OK',
        'StartTime': '2012-03-07T14:44+06:00',
        'EndTime': '2012-03-07T14:45+06:00',
        'Messages': <dynamic>[
          <String, dynamic>{
            'MessageId': 'Base.1.0.PropertyNotWritable',
            'RelatedProperties': <String>['SKU'],
            'Message': 'The property SKU is a read only property and cannot be '
                'assigned a value',
            'MessageArgs': <String>['SKU'],
            'Severity': 'Warning',
          },
        ],
      });

      expect(task.id, '545');
      expect(task.name, 'Task 545');
      expect(task.state, 'Completed');
      expect(task.status, 'OK');
      expect(task.startTime, DateTime.parse('2012-03-07T14:44+06:00'));
      expect(task.endTime, DateTime.parse('2012-03-07T14:45+06:00'));
      expect(task.percentComplete, isNull);
      expect(task.isTerminal, isTrue);
      expect(task.isSuccess, isTrue);
      expect(task.isFailed, isFalse);
      expect(task.failureReason, isNull);
      expect(task.statusNote, isNull);
      expect(task.taskMonitorUri, isNull);
      expect(task.messages, hasLength(1));
      expect(task.messages.first.messageId, 'Base.1.0.PropertyNotWritable');
      expect(task.messages.first.message, contains('SKU'));
      expect(task.messages.first.messageArgs, <String>['SKU']);
      expect(task.messages.first.severity, 'Warning');
      expect(task.messages.first.relatedProperties, <String>['SKU']);
    });

    test('derives id from @odata.id last segment when Id is absent', () {
      final RedfishTask task = RedfishTask.fromJson(<String, dynamic>{
        '@odata.type': '#Task.v1_7_3.Task',
        '@odata.id': '/redfish/v1/TaskService/TaskMonitors/42',
        'TaskState': 'Running',
      });
      expect(task.id, '42');
      expect(task.state, 'Running');
      expect(task.isTerminal, isFalse);
    });

    test('tolerates an unparseable timestamp without throwing', () {
      final RedfishTask task = RedfishTask.fromJson(<String, dynamic>{
        'Id': '1',
        'TaskState': 'New',
        'StartTime': 'not-a-date',
      });
      expect(task.id, '1');
      expect(task.startTime, isNull);
    });

    test('parses PercentComplete when present (0-100)', () {
      final RedfishTask task = RedfishTask.fromJson(<String, dynamic>{
        'Id': '1',
        'TaskState': 'Running',
        'PercentComplete': 42,
      });
      expect(task.percentComplete, 42);
    });

    test('exposes the task monitor URI when published', () {
      final RedfishTask task = RedfishTask.fromJson(<String, dynamic>{
        'Id': '1',
        'TaskState': 'Running',
        'TaskMonitor': '/redfish/v1/TaskService/TaskMonitors/1',
      });
      expect(task.taskMonitorUri, '/redfish/v1/TaskService/TaskMonitors/1');
    });
  });

  group('RedfishTask terminal-state classification', () {
    const Map<String, bool> terminalStates = <String, bool>{
      'New': false,
      'Starting': false,
      'Running': false,
      'Suspended': false,
      'Interrupted': false,
      'Pending': false,
      'Stopping': false,
      'Cancelling': false,
      'Completed': true,
      'Killed': true,
      'Exception': true,
      'Service': true,
      'Cancelled': true,
    };

    terminalStates.forEach((String state, bool terminal) {
      test('$state isTerminal == $terminal', () {
        final RedfishTask task =
            RedfishTask(id: '1', state: state, status: 'OK');
        expect(task.isTerminal, terminal);
        // A non-terminal state is never success/failure; the poller keeps
        // polling.
        if (!terminal) {
          expect(task.isSuccess, isFalse);
          expect(task.isFailed, isFalse);
          expect(task.failureReason, isNull);
        }
      });
    });

    test('Completed with OK (or absent status) is success', () {
      expect(
        const RedfishTask(id: '1', state: 'Completed', status: 'OK').isSuccess,
        isTrue,
      );
      expect(
        const RedfishTask(id: '1', state: 'Completed').isSuccess,
        isTrue,
      );
      expect(
        const RedfishTask(id: '1', state: 'Completed', status: 'OK').isFailed,
        isFalse,
      );
    });

    test('Completed with Warning/Critical is not clean success', () {
      final RedfishTask warning =
          const RedfishTask(id: '1', state: 'Completed', status: 'Warning');
      expect(warning.isSuccess, isFalse);
      expect(warning.isFailed, isTrue);
      expect(warning.statusNote, 'Completed with Warning');
      expect(warning.failureReason, isNotNull);

      final RedfishTask critical =
          const RedfishTask(id: '1', state: 'Completed', status: 'Critical');
      expect(critical.isFailed, isTrue);
      expect(critical.statusNote, 'Completed with Critical');
    });

    test('Killed/Exception/Service/Cancelled are terminal failures', () {
      for (final String state in <String>[
        'Killed',
        'Exception',
        'Service',
        'Cancelled',
      ]) {
        final RedfishTask task = RedfishTask(id: '1', state: state);
        expect(task.isTerminal, isTrue, reason: state);
        expect(task.isFailed, isTrue, reason: state);
        expect(task.isSuccess, isFalse, reason: state);
        expect(task.failureReason, 'Task $state', reason: state);
      }
    });

    test('failureReason prefers Message.Message, then MessageId', () {
      final RedfishTask withMessage = const RedfishTask(
        id: '1',
        state: 'Exception',
        messages: <TaskMessage>[
          TaskMessage(
            messageId: 'Update.1.0.UpdateFailed',
            message: 'The update image was rejected.',
            severity: 'Critical',
          ),
        ],
      );
      expect(withMessage.failureReason, 'The update image was rejected.');

      final RedfishTask idOnly = const RedfishTask(
        id: '1',
        state: 'Killed',
        messages: <TaskMessage>[
          TaskMessage(messageId: 'Base.1.0.GeneralError'),
        ],
      );
      expect(idOnly.failureReason, 'Base.1.0.GeneralError');
    });

    test('fromJsonString convenience parses a raw JSON body', () {
      final RedfishTask task = RedfishTask.fromJsonString(
        '{"@odata.id": "/redfish/v1/TaskService/Tasks/545",'
        ' "Id": "545", "TaskState": "Completed", "TaskStatus": "OK"}',
      );
      expect(task.id, '545');
      expect(task.isSuccess, isTrue);
    });
  });

  group('TaskMessage.fromJson', () {
    test('parses a full message with args + related properties', () {
      final TaskMessage m = TaskMessage.fromJson(<String, dynamic>{
        'MessageId': 'Base.1.0.PropertyNotWritable',
        'Message': 'The property SKU is a read only property',
        'MessageArgs': <String>['SKU'],
        'Severity': 'Warning',
        'RelatedProperties': <String>['SKU'],
      });
      expect(m.messageId, 'Base.1.0.PropertyNotWritable');
      expect(m.message, contains('SKU'));
      expect(m.messageArgs, <String>['SKU']);
      expect(m.severity, 'Warning');
      expect(m.relatedProperties, <String>['SKU']);
    });

    test('tolerates missing/odd-shaped fields', () {
      final TaskMessage m = TaskMessage.fromJson(<String, dynamic>{
        'MessageId': 'Base.1.0.GeneralError',
      });
      expect(m.messageId, 'Base.1.0.GeneralError');
      expect(m.message, isNull);
      expect(m.messageArgs, isEmpty);
      expect(m.severity, isNull);
      expect(m.relatedProperties, isEmpty);
    });
  });
}
