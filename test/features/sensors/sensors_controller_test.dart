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
