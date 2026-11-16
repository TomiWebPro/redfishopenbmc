import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/bios/bios_controller.dart';
import 'package:redfishopenbmc/features/bios/bios_service.dart';
import 'package:redfishopenbmc/features/bios/models/bios_models.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

class _FakeClient extends RedfishClient {
  _FakeClient(this._responses)
      : super(profile: const ConnectionProfile(host: 'h'));

  final Map<String, dynamic> _responses;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final dynamic body = _responses[path];
    if (body == null) {
      throw RedfishException(message: 'not found: $path');
    }
    return Map<String, dynamic>.from(body as Map);
  }
}

void main() {
  group('BiosController (#028 read-only)', () {
    test('load populates current and pending on success', () async {
      final _FakeClient client = _FakeClient(<String, dynamic>{
        '/redfish/v1/Systems/1/Bios': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems/1/Bios',
          'Id': 'Bios',
          'Name': 'BIOS Configuration Current Settings',
          'Attributes': <String, dynamic>{'QuietBoot': true},
          '@Redfish.Settings': <String, dynamic>{
            'ETag': 'abc',
            'SettingsObject': <String, dynamic>{
              '@odata.id': '/redfish/v1/Systems/1/Bios/Settings',
            },
          },
        },
        '/redfish/v1/Systems/1/Bios/Settings': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems/1/Bios/Settings',
          'Attributes': <String, dynamic>{'QuietBoot': false},
        },
      });
      final BiosService service = BiosService(
        client: client,
        systemId: 'bmc1',
        systemResourceUri: '/redfish/v1/Systems/1',
      );
      final BiosController controller = BiosController(service: service);

      await controller.load();

      expect(controller.state.loading, isFalse);
      expect(controller.state.error, isNull);
      expect(controller.state.current, isA<BiosResource>());
      expect(controller.state.current?.attributes.values['QuietBoot'], isTrue);
      expect(controller.state.pending, isA<BiosPendingSettings>());
      expect(
        controller.state.pending?.attributes.values['QuietBoot'],
        isFalse,
      );
      controller.dispose();
    });

    test('load records RedfishException as error state', () async {
      final BiosService service = BiosService(
        client: null,
        systemId: 'bmc1',
      );
      final BiosController controller = BiosController(service: service);

      await controller.load();

      expect(controller.state.loading, isFalse);
      expect(controller.state.current, isNull);
      expect(controller.state.error, isNotNull);
      controller.dispose();
    });
  });
}
