import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/bios/models/bios_models.dart';

void main() {
  group('BiosResource.fromJson', () {
    test('parses current Bios resource with @Redfish.Settings and actions', () {
      final BiosResource bios = BiosResource.fromJson(<String, dynamic>{
        '@odata.type': '#Bios.v1_2_2.Bios',
        '@odata.id': '/redfish/v1/Systems/437XR1138R2/Bios',
        'Id': 'Bios',
        'Name': 'BIOS Configuration Current Settings',
        'AttributeRegistry': 'BiosAttributeRegistryP89.v1_0_0',
        'Attributes': <String, dynamic>{
          'AdminPhone': '',
          'BootMode': 'Uefi',
          'EmbeddedSata': 'Raid',
          'ProcTurboMode': 'Enabled',
        },
        'ResetBiosToDefaultsPending': true,
        '@Redfish.Settings': <String, dynamic>{
          '@odata.type': '#Settings.v1_3_5.Settings',
          'ETag': '9234ac83b9700123cc32',
          'Messages': <dynamic>[
            <String, dynamic>{
              'MessageId': 'Base.1.0.SettingsFailed',
              'RelatedProperties': <dynamic>['/Attributes/ProcTurboMode'],
            },
          ],
          'SettingsObject': <String, dynamic>{
            '@odata.id': '/redfish/v1/Systems/437XR1138R2/Bios/Settings',
          },
          'Time': '2016-03-07T14:44.30-05:00',
        },
        'Actions': <String, dynamic>{
          '#Bios.ResetBios': <String, dynamic>{
            'target':
                '/redfish/v1/Systems/437XR1138R2/Bios/Actions/Bios.ResetBios',
          },
          '#Bios.ChangePassword': <String, dynamic>{
            'target':
                '/redfish/v1/Systems/437XR1138R2/Bios/Actions/Bios.ChangePassword',
          },
        },
      });

      expect(bios.id, 'Bios');
      expect(bios.odataType, '#Bios.v1_2_2.Bios');
      expect(bios.attributeRegistry, 'BiosAttributeRegistryP89.v1_0_0');
      expect(bios.attributes.values['EmbeddedSata'], 'Raid');
      expect(bios.resetBiosToDefaultsPending, isTrue);
      expect(bios.settings, isNotNull);
      expect(bios.settingsEtag, '9234ac83b9700123cc32');
      expect(
        bios.pendingSettingsUri,
        '/redfish/v1/Systems/437XR1138R2/Bios/Settings',
      );
      expect(bios.settings!.messages, hasLength(1));
      expect(
          bios.settings!.messages.first.messageId, 'Base.1.0.SettingsFailed');
      expect(
        bios.settings!.messages.first.relatedProperties,
        contains('/Attributes/ProcTurboMode'),
      );
      expect(
        bios.actions.resetBiosTarget,
        '/redfish/v1/Systems/437XR1138R2/Bios/Actions/Bios.ResetBios',
      );
      expect(bios.actions.changePasswordTarget, isNotNull);
    });

    test('tolerates missing optional fields', () {
      final BiosResource bios =
          BiosResource.fromJson(const <String, dynamic>{});
      expect(bios.attributes.values, isEmpty);
      expect(bios.settings, isNull);
      expect(bios.pendingSettingsUri, isNull);
      expect(bios.actions.resetBiosTarget, isNull);
    });
  });

  group('BiosPendingSettings.fromJson', () {
    test('parses pending settings attributes', () {
      final BiosPendingSettings pending =
          BiosPendingSettings.fromJson(<String, dynamic>{
        '@odata.type': '#Bios.v1_2_2.Bios',
        '@odata.id': '/redfish/v1/Systems/437XR1138R2/Bios/Settings',
        'Id': 'Settings',
        'Name': 'BIOS Configuration Pending Settings',
        'AttributeRegistry': 'BiosAttributeRegistryP89.v1_0_0',
        'Attributes': <String, dynamic>{
          'EmbeddedSata': 'Ahci',
          'ProcTurboMode': 'Disabled',
        },
      });

      expect(pending.id, 'Settings');
      expect(pending.attributes.values['EmbeddedSata'], 'Ahci');
      expect(pending.attributes.values['ProcTurboMode'], 'Disabled');
    });
  });

  group('BiosAttributes.diffKeys', () {
    test('returns keys that differ between current and pending', () {
      const BiosAttributes current = BiosAttributes(<String, dynamic>{
        'EmbeddedSata': 'Raid',
        'ProcTurboMode': 'Enabled',
        'BootMode': 'Uefi',
      });
      const BiosAttributes pending = BiosAttributes(<String, dynamic>{
        'EmbeddedSata': 'Ahci',
        'ProcTurboMode': 'Disabled',
        'BootMode': 'Uefi',
        'AdminPhone': '(404) 555-1212',
      });

      final Set<String> diff = BiosAttributes.diffKeys(current, pending);
      expect(diff,
          containsAll(<String>{'EmbeddedSata', 'ProcTurboMode', 'AdminPhone'}));
      expect(diff, isNot(contains('BootMode')));
    });
  });
}
