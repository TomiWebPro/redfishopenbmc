import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/overview/models/boot_settings.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';

void main() {
  group('IndicatorLed.toRedfish (§016 PATCH flow)', () {
    test('maps the writable states to the schema enum values', () {
      expect(IndicatorLed.lit.toRedfish, 'Lit');
      expect(IndicatorLed.blinking.toRedfish, 'Blinking');
      expect(IndicatorLed.off.toRedfish, 'Off');
    });

    test('Unknown is not a writable PATCH value (schema-deprecated)', () {
      expect(IndicatorLed.unknown.toRedfish, isNull);
    });

    test('writableValues is exactly the schema enum minus Unknown', () {
      expect(
        IndicatorLed.writableValues,
        <String>['Lit', 'Blinking', 'Off'],
      );
    });

    test('fromRedfish round-trips every writable value', () {
      for (final String v in IndicatorLed.writableValues) {
        expect(IndicatorLed.fromRedfish(v).toRedfish, v);
      }
    });
  });

  group('BootSettings', () {
    test('parses the full served Boot block incl. the allow-list annotation',
        () {
      final BootSettings s = BootSettings.fromRedfish(<String, dynamic>{
        'Boot': <String, dynamic>{
          'BootSourceOverrideEnabled': 'Once',
          'BootSourceOverrideMode': 'UEFI',
          'BootSourceOverrideTarget': 'Pxe',
          'UefiTargetBootSourceOverride': '/0x31/0x33/0x01/0x01',
          'BootSourceOverrideTarget@Redfish.AllowableValues': <String>[
            'None',
            'Pxe',
            'Cd',
            'Usb',
            'Hdd',
            'BiosSetup',
            'Utilities',
            'Diags',
            'SDCard',
            'UefiTarget',
          ],
        },
      });

      expect(s.enabled, 'Once');
      expect(s.mode, 'UEFI');
      expect(s.target, 'Pxe');
      expect(s.uefiTarget, '/0x31/0x33/0x01/0x01');
      expect(s.hasAllowableTargets, isTrue);
      expect(s.allowableTargets, contains('Pxe'));
      expect(s.allows('Pxe'), isTrue);
      expect(s.allows('Cd'), isTrue);
      expect(s.allows('Bogus'), isFalse);
      // Case-sensitive per the schema enum.
      expect(s.allows('pxe'), isFalse);
    });

    test('missing / partial Boot block degrades to all-null + empty list', () {
      final BootSettings empty = BootSettings.fromRedfish(<String, dynamic>{});
      expect(empty.enabled, isNull);
      expect(empty.target, isNull);
      expect(empty.mode, isNull);
      expect(empty.hasAllowableTargets, isFalse);
      expect(empty.allows('Pxe'), isFalse);

      final BootSettings partial = BootSettings.fromRedfish(<String, dynamic>{
        'Boot': <String, dynamic>{'BootSourceOverrideTarget': 'Hdd'},
      });
      expect(partial.target, 'Hdd');
      expect(partial.enabled, isNull);
      expect(partial.hasAllowableTargets, isFalse);
    });

    test('null-valued Boot + non-list annotation are tolerated', () {
      final BootSettings s = BootSettings.fromRedfish(<String, dynamic>{
        'Boot': null,
      });
      expect(s.enabled, isNull);
      expect(s.hasAllowableTargets, isFalse);

      final BootSettings s2 = BootSettings.fromRedfish(<String, dynamic>{
        'Boot': <String, dynamic>{
          'BootSourceOverrideTarget@Redfish.AllowableValues': 'not-a-list',
        },
      });
      expect(s2.hasAllowableTargets, isFalse);
    });

    test('copyWith overrides only the given fields', () {
      const BootSettings s = BootSettings(target: 'Pxe');
      final BootSettings c = s.copyWith(target: 'Cd', enabled: 'Continuous');
      expect(c.target, 'Cd');
      expect(c.enabled, 'Continuous');
      expect(c.allowableTargets, isEmpty);
      expect(s.target, 'Pxe');
    });
  });
}
