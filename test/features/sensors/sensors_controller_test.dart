import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_controller.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';

void main() {
  group('SensorsController delta polling (#007)', () {
    test(
        'reuses the chassis list when a poll changes nothing, but still '
        'advances sparkline history', () async {
      final _ScriptedSensorsService service = _ScriptedSensorsService();
      final SensorsController controller = SensorsController(service: service);

      await controller.load();
      final List<ChassisSensors> first = controller.state.chassis;
      expect(first, hasLength(1));
      expect(controller.state.history['thermal|1U|CPU'], <double>[40.0]);

      await controller.load();
      expect(service.calls, 2);
      // Identical readings → same list instance, so unchanged tiles are not
      // handed new data and do not rebuild.
      expect(identical(controller.state.chassis, first), isTrue);
      // A flat reading still grows its ring buffer (trend keeps advancing).
      expect(controller.state.history['thermal|1U|CPU'], <double>[40.0, 40.0]);
    });

    test('publishes a fresh chassis list when a reading changes', () async {
      final _ScriptedSensorsService service = _ScriptedSensorsService(
        reading: (int poll) => 39.0 + poll,
      );
      final SensorsController controller = SensorsController(service: service);

      await controller.load();
      final List<ChassisSensors> first = controller.state.chassis;
      await controller.load();

      expect(service.calls, 2);
      expect(identical(controller.state.chassis, first), isFalse);
      expect(controller.state.history['thermal|1U|CPU'], <double>[40.0, 41.0]);
    });
  });

  group('SensorsController last-updated stamp (#007)', () {
    test('is null before the first successful poll, then uses the clock',
        () async {
      final DateTime t1 = DateTime(2026, 11, 17, 19, 2, 3);
      final SensorsController controller = SensorsController(
        service: _ScriptedSensorsService(),
        clock: () => t1,
      );
      expect(controller.state.lastUpdated, isNull);

      await controller.load();
      expect(controller.state.lastUpdated, t1);
    });

    test('advances on every successful poll, including an unchanged one',
        () async {
      final List<DateTime> ticks = <DateTime>[
        DateTime(2026, 11, 17, 19, 2, 3),
        DateTime(2026, 11, 17, 19, 2, 13),
      ];
      int i = 0;
      final SensorsController controller = SensorsController(
        service: _ScriptedSensorsService(), // flat readings → delta poll
        clock: () => ticks[i++],
      );

      await controller.load();
      final List<ChassisSensors> first = controller.state.chassis;
      await controller.load();

      // The 2nd poll is a delta (same list instance) yet the stamp advances —
      // "last updated" means last checked, not last changed.
      expect(identical(controller.state.chassis, first), isTrue);
      expect(controller.state.lastUpdated, ticks[1]);
    });

    test('a failed poll leaves the previous stamp intact', () async {
      final DateTime t1 = DateTime(2026, 11, 17, 19, 2, 3);
      final _FailingOnceSensorsService service = _FailingOnceSensorsService();
      final SensorsController controller = SensorsController(
        service: service,
        clock: () => t1,
      );

      await controller.load();
      expect(controller.state.lastUpdated, t1);

      await controller.load(); // second poll throws
      expect(controller.state.error, isNotNull);
      expect(controller.state.lastUpdated, t1);
    });
  });
}

/// Service stub whose second poll fails (last-updated-on-error test).
class _FailingOnceSensorsService extends SensorsService {
  _FailingOnceSensorsService() : super(client: null, systemId: 'x');

  int calls = 0;

  @override
  Future<List<ChassisSensors>> fetchAll() async {
    calls++;
    if (calls == 2) {
      throw StateError('second poll failed');
    }
    return const <ChassisSensors>[
      ChassisSensors(
        chassisId: '1U',
        thermal: <ThermalReading>[
          ThermalReading(name: 'CPU', readingCelsius: 40.0),
        ],
      ),
    ];
  }
}

/// Minimal service stub returning one CPU temperature per poll.
class _ScriptedSensorsService extends SensorsService {
  _ScriptedSensorsService({this.reading = _flat})
      : super(client: null, systemId: 'x');

  static double _flat(int _) => 40.0;

  /// Reading for the 1-based [poll] number.
  final double Function(int poll) reading;

  int calls = 0;

  @override
  Future<List<ChassisSensors>> fetchAll() async {
    calls++;
    return <ChassisSensors>[
      ChassisSensors(
        chassisId: '1U',
        thermal: <ThermalReading>[
          ThermalReading(
            name: 'CPU',
            readingCelsius: reading(calls),
          ),
        ],
      ),
    ];
  }
}
