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

class _ResettingService extends BiosService {
  _ResettingService({required super.client, required super.systemId});

  bool resetCalled = false;
  bool failReset = false;

  @override
  Future<Map<String, dynamic>> resetBios(BiosResource bios) async {
    resetCalled = true;
    if (failReset) {
      throw const RedfishException(message: 'reset failed');
    }
    return <String, dynamic>{};
  }

  @override
  Future<({BiosResource current, BiosPendingSettings? pending})>
      fetchBiosWithPending() async {
    return (
      current: const BiosResource(
        id: 'Bios',
        name: 'BIOS',
        attributes: BiosAttributes(<String, dynamic>{'BootMode': 'Uefi'}),
      ),
      pending: null,
    );
  }
}

class _PatchingService extends BiosService {
  _PatchingService({required super.client, required super.systemId});

  bool patchCalled = false;
  bool failPatch = false;
  Map<String, dynamic>? lastAttributes;

  @override
  Future<Map<String, dynamic>> patchPendingAttributes(
    BiosResource bios,
    Map<String, dynamic> attributes,
  ) async {
    patchCalled = true;
    lastAttributes = Map<String, dynamic>.from(attributes);
    if (failPatch) {
      throw const RedfishException(message: 'patch failed');
    }
    return <String, dynamic>{};
  }

  @override
  Future<({BiosResource current, BiosPendingSettings? pending})>
      fetchBiosWithPending() async {
    return (
      current: const BiosResource(
        id: 'Bios',
        name: 'BIOS',
        attributes: BiosAttributes(<String, dynamic>{'QuietBoot': false}),
        settings: BiosSettingsAnnotation(
          etag: 'e1',
          settingsObjectUri: '/redfish/v1/Systems/1/Bios/Settings',
        ),
      ),
      pending: null,
    );
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

    test('resetBios calls service and reloads on success', () async {
      final _ResettingService service = _ResettingService(
        client: _FakeClient(<String, dynamic>{}),
        systemId: 'bmc1',
      );
      final BiosController controller = BiosController(service: service);
      const BiosResource bios = BiosResource(
        id: 'Bios',
        actions: BiosActions(
          resetBiosTarget: '/redfish/v1/Systems/1/Bios/Actions/Bios.ResetBios',
        ),
      );

      await controller.resetBios(bios);

      expect(service.resetCalled, isTrue);
      expect(controller.state.resetting, isFalse);
      expect(controller.state.error, isNull);
      expect(controller.state.current, isNotNull);
      controller.dispose();
    });

    test('resetBios records normalized error and clears busy state', () async {
      final _ResettingService service = _ResettingService(
        client: _FakeClient(<String, dynamic>{}),
        systemId: 'bmc1',
      )..failReset = true;
      final BiosController controller = BiosController(service: service);
      const BiosResource bios = BiosResource(
        id: 'Bios',
        actions: BiosActions(
          resetBiosTarget: '/redfish/v1/Systems/1/Bios/Actions/Bios.ResetBios',
        ),
      );

      await controller.resetBios(bios);

      expect(service.resetCalled, isTrue);
      expect(controller.state.resetting, isFalse);
      expect(controller.state.error, contains('reset failed'));
      controller.dispose();
    });

    test('applyPendingAttributes patches and reloads on success', () async {
      final _PatchingService service = _PatchingService(
        client: _FakeClient(<String, dynamic>{}),
        systemId: 'bmc1',
      );
      final BiosController controller = BiosController(service: service);
      const BiosResource bios = BiosResource(
        id: 'Bios',
        settings: BiosSettingsAnnotation(
          etag: 'e1',
          settingsObjectUri: '/redfish/v1/Systems/1/Bios/Settings',
        ),
      );

      await controller.applyPendingAttributes(
        bios,
        <String, dynamic>{'QuietBoot': false},
      );

      expect(service.patchCalled, isTrue);
      expect(
        service.lastAttributes,
        equals(<String, dynamic>{'QuietBoot': false}),
      );
      expect(controller.state.applying, isFalse);
      expect(controller.state.error, isNull);
      expect(controller.state.current, isNotNull);
      controller.dispose();
    });

    test('applyPendingAttributes records normalized error and clears busy',
        () async {
      final _PatchingService service = _PatchingService(
        client: _FakeClient(<String, dynamic>{}),
        systemId: 'bmc1',
      )..failPatch = true;
      final BiosController controller = BiosController(service: service);
      const BiosResource bios = BiosResource(
        id: 'Bios',
        settings: BiosSettingsAnnotation(
          etag: 'e1',
          settingsObjectUri: '/redfish/v1/Systems/1/Bios/Settings',
        ),
      );

      await controller.applyPendingAttributes(
        bios,
        <String, dynamic>{'QuietBoot': false},
      );

      expect(service.patchCalled, isTrue);
      expect(controller.state.applying, isFalse);
      expect(controller.state.error, contains('patch failed'));
      controller.dispose();
    });
  });
}
