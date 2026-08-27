import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';

void main() {
  group('SystemSnapshot', () {
    test('fromSystemJson maps Health/PowerState/Manufacturer/Model', () {
      final SystemSnapshot s = SystemSnapshot.fromSystemJson(<String, dynamic>{
        'Status': <String, dynamic>{'Health': 'OK'},
        'PowerState': 'On',
        'Manufacturer': 'ACME',
        'Model': 'Server-X',
        'SerialNumber': 'SN123',
      });
      expect(s.health, Health.ok);
      expect(s.powerState, PowerState.on);
      expect(s.manufacturer, 'ACME');
      expect(s.model, 'Server-X');
      expect(s.serialNumber, 'SN123');
    });

    test('fromSystemJson tolerates missing fields as unknown', () {
      final SystemSnapshot s =
          SystemSnapshot.fromSystemJson(<String, dynamic>{});
      expect(s.health, Health.unknown);
      expect(s.powerState, PowerState.unknown);
    });

    test('HealthX.fromStatus maps known and unknown values', () {
      expect(HealthX.fromStatus('OK'), Health.ok);
      expect(HealthX.fromStatus('Warning'), Health.warning);
      expect(HealthX.fromStatus('Critical'), Health.critical);
      expect(HealthX.fromStatus('Nonsense'), Health.unknown);
      expect(HealthX.fromStatus(null), Health.unknown);
      expect(Health.ok.label, 'OK');
      expect(Health.warning.label, 'Warning');
      expect(Health.critical.label, 'Critical');
      expect(Health.unknown.label, 'Unknown');
    });

    test('PowerStateX.fromRedfish maps known and unknown values', () {
      expect(PowerStateX.fromRedfish('On'), PowerState.on);
      expect(PowerStateX.fromRedfish('Off'), PowerState.off);
      expect(PowerStateX.fromRedfish('Maybe'), PowerState.unknown);
      expect(PowerStateX.fromRedfish(null), PowerState.unknown);
      expect(PowerState.on.label, 'On');
      expect(PowerState.off.label, 'Off');
    });

    test('toJson/fromJson round-trips', () {
      final SystemSnapshot s = SystemSnapshot(
        health: Health.warning,
        powerState: PowerState.off,
        manufacturer: 'ACME',
        model: 'X',
        serialNumber: 'SN',
        lastUpdated: DateTime.utc(2026, 5, 5),
      );
      final SystemSnapshot back = SystemSnapshot.fromJson(s.toJson());
      expect(back.health, Health.warning);
      expect(back.powerState, PowerState.off);
      expect(back.manufacturer, 'ACME');
      expect(back.lastUpdated, DateTime.utc(2026, 5, 5));
    });
  });
}
