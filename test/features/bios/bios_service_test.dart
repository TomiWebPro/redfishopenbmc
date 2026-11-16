import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:redfishopenbmc/features/bios/bios_service.dart';
import 'package:redfishopenbmc/features/bios/models/bios_models.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

class _MethodPathMatcher extends HttpRequestMatcher {
  const _MethodPathMatcher();

  @override
  bool matches(RequestOptions ongoingRequest, Request matcher) {
    if (matcher.method?.name != null &&
        ongoingRequest.method != matcher.method!.name) {
      return false;
    }
    final dynamic route = matcher.route;
    final String routeStr = route is String ? route : route.toString();
    final String path = ongoingRequest.path;
    final bool pathMatches = path == routeStr ||
        (Uri.tryParse(path)?.path == routeStr) ||
        path.endsWith(routeStr);
    if (!pathMatches) return false;

    if (matcher.data != null) {
      final dynamic actual = ongoingRequest.data;
      if (actual is! Map || !_mapContains(actual, matcher.data as Map)) {
        return false;
      }
    }
    final Map<String, dynamic>? expectedHeaders = matcher.headers;
    if (expectedHeaders != null && expectedHeaders.isNotEmpty) {
      for (final MapEntry<String, dynamic> e in expectedHeaders.entries) {
        if (ongoingRequest.headers[e.key]?.toString() != e.value.toString()) {
          return false;
        }
      }
    }
    return true;
  }

  bool _mapContains(
      Map<dynamic, dynamic> actual, Map<dynamic, dynamic> expected) {
    for (final dynamic key in expected.keys) {
      final dynamic actualValue = actual[key];
      final dynamic expectedValue = expected[key];
      if (actualValue is Map<dynamic, dynamic> &&
          expectedValue is Map<dynamic, dynamic>) {
        if (!_mapContains(actualValue, expectedValue)) return false;
      } else if (actualValue != expectedValue) {
        return false;
      }
    }
    return true;
  }
}

DioAdapter adapter() => DioAdapter(
      dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
      matcher: const _MethodPathMatcher(),
    );

RedfishClient clientWithAdapter(DioAdapter a) => RedfishClient(
      profile: const ConnectionProfile(host: 'bmc1.local', name: 'bmc1'),
      dio: a.dio,
    );

Map<String, dynamic> biosBody({
  String biosUri = '/redfish/v1/Systems/437XR1138R2/Bios',
  String settingsUri = '/redfish/v1/Systems/437XR1138R2/Bios/Settings',
  String etag = '9234ac83b9700123cc32',
}) =>
    <String, dynamic>{
      '@odata.type': '#Bios.v1_2_2.Bios',
      '@odata.id': biosUri,
      'Id': 'Bios',
      'Name': 'BIOS Configuration Current Settings',
      'AttributeRegistry': 'BiosAttributeRegistryP89.v1_0_0',
      'Attributes': <String, dynamic>{
        'EmbeddedSata': 'Raid',
        'ProcTurboMode': 'Enabled',
      },
      '@Redfish.Settings': <String, dynamic>{
        '@odata.type': '#Settings.v1_3_5.Settings',
        'ETag': etag,
        'Messages': <dynamic>[
          <String, dynamic>{
            'MessageId': 'Base.1.0.SettingsFailed',
            'RelatedProperties': <dynamic>['/Attributes/ProcTurboMode'],
          },
        ],
        'SettingsObject': <String, dynamic>{'@odata.id': settingsUri},
      },
      'Actions': <String, dynamic>{
        '#Bios.ResetBios': <String, dynamic>{
          'target': '$biosUri/Actions/Bios.ResetBios',
        },
      },
    };

Map<String, dynamic> pendingBody({
  String settingsUri = '/redfish/v1/Systems/437XR1138R2/Bios/Settings',
}) =>
    <String, dynamic>{
      '@odata.type': '#Bios.v1_2_2.Bios',
      '@odata.id': settingsUri,
      'Id': 'Settings',
      'Name': 'BIOS Configuration Pending Settings',
      'AttributeRegistry': 'BiosAttributeRegistryP89.v1_0_0',
      'Attributes': <String, dynamic>{
        'EmbeddedSata': 'Ahci',
        'ProcTurboMode': 'Disabled',
      },
    };

SystemFeatures featuresWithBios({
  String systemUri = '/redfish/v1/Systems/437XR1138R2',
  String biosUri = '/redfish/v1/Systems/437XR1138R2/Bios',
}) {
  return SystemFeatures(
    systemId: 'bmc1',
    raw: <String, dynamic>{
      systemUri: <String, dynamic>{
        '@odata.id': systemUri,
        '@odata.type': '#ComputerSystem.v1_22_0.ComputerSystem',
        'Bios': <String, dynamic>{'@odata.id': biosUri},
      },
    },
  );
}

void main() {
  group('BiosService.fetchBios / fetchPendingSettings', () {
    test('resolves Bios URI from discovery and fetches pending settings',
        () async {
      final DioAdapter a = adapter();
      const String biosUri = '/redfish/v1/Systems/437XR1138R2/Bios';
      const String settingsUri =
          '/redfish/v1/Systems/437XR1138R2/Bios/Settings';
      a.onGet(biosUri, (server) => server.reply(200, biosBody()));
      a.onGet(settingsUri, (server) => server.reply(200, pendingBody()));

      final BiosService service = BiosService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
        features: featuresWithBios(),
      );

      final BiosResource bios = await service.fetchBios();
      expect(bios.pendingSettingsUri, settingsUri);
      expect(bios.settingsEtag, '9234ac83b9700123cc32');

      final BiosPendingSettings? pending =
          await service.fetchPendingSettings(bios);
      expect(pending, isNotNull);
      expect(pending!.attributes.values['EmbeddedSata'], 'Ahci');

      final diff = BiosAttributes.diffKeys(
        bios.attributes,
        pending.attributes,
      );
      expect(diff, containsAll(<String>{'EmbeddedSata', 'ProcTurboMode'}));
    });

    test('returns null pending settings when no SettingsObject is advertised',
        () async {
      final DioAdapter a = adapter();
      const String biosUri = '/redfish/v1/Systems/437XR1138R2/Bios';
      a.onGet(
        biosUri,
        (server) => server.reply(200, <String, dynamic>{
          '@odata.type': '#Bios.v1_2_2.Bios',
          '@odata.id': biosUri,
          'Id': 'Bios',
          'Attributes': <String, dynamic>{},
        }),
      );
      final BiosService service = BiosService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
        features: featuresWithBios(),
      );
      final BiosResource bios = await service.fetchBios();
      expect(await service.fetchPendingSettings(bios), isNull);
    });

    test('surfaces friendly not-connected error', () async {
      final BiosService service = BiosService(client: null, systemId: 'bmc1');
      await expectLater(
        service.fetchBios(),
        throwsA(
          isA<RedfishException>().having(
            (RedfishException e) => e.errorCode,
            'errorCode',
            'Base.1.0.NotConnected',
          ),
        ),
      );
    });
  });

  group('BiosService.patchPendingAttributes', () {
    test('PATCHes pending settings with settings ETag as If-Match', () async {
      final DioAdapter a = adapter();
      const String settingsUri =
          '/redfish/v1/Systems/437XR1138R2/Bios/Settings';
      a.onPatch(
        settingsUri,
        (server) => server.reply(204, null),
        data: <String, dynamic>{
          'Attributes': <String, dynamic>{'ProcTurboMode': 'Disabled'},
        },
        headers: <String, dynamic>{'If-Match': '"9234ac83b9700123cc32"'},
      );
      final BiosService service = BiosService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
      );
      final BiosResource bios = BiosResource.fromJson(biosBody());

      final Map<String, dynamic> result = await service.patchPendingAttributes(
        bios,
        <String, dynamic>{'ProcTurboMode': 'Disabled'},
      );
      expect(result, isEmpty);
    });

    test('throws when no pending settings URI is advertised', () async {
      final BiosService service = BiosService(
        client: clientWithAdapter(adapter()),
        systemId: 'bmc1',
      );
      final BiosResource bios = BiosResource.fromJson(<String, dynamic>{
        '@odata.id': '/redfish/v1/Systems/1/Bios',
        'Attributes': <String, dynamic>{},
      });
      await expectLater(
        service.patchPendingAttributes(bios, <String, dynamic>{'A': 1}),
        throwsA(
          isA<RedfishException>().having(
            (RedfishException e) => e.errorCode,
            'errorCode',
            'Base.1.0.PropertyNotWritable',
          ),
        ),
      );
    });
  });

  group('BiosService.resetBios', () {
    test('POSTs to advertised ResetBios target', () async {
      final DioAdapter a = adapter();
      const String target =
          '/redfish/v1/Systems/437XR1138R2/Bios/Actions/Bios.ResetBios';
      a.onPost(
        target,
        (server) => server.reply(204, null),
        data: <String, dynamic>{},
      );
      final BiosService service = BiosService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
      );
      final BiosResource bios = BiosResource.fromJson(biosBody());
      final Map<String, dynamic> result = await service.resetBios(bios);
      expect(result, isEmpty);
    });

    test('throws when ResetBios action is missing', () async {
      final BiosService service = BiosService(
        client: clientWithAdapter(adapter()),
        systemId: 'bmc1',
      );
      final BiosResource bios = BiosResource.fromJson(<String, dynamic>{
        '@odata.id': '/redfish/v1/Systems/1/Bios',
        'Attributes': <String, dynamic>{},
      });
      await expectLater(
        service.resetBios(bios),
        throwsA(
          isA<RedfishException>().having(
            (RedfishException e) => e.errorCode,
            'errorCode',
            'Base.1.0.ActionNotSupported',
          ),
        ),
      );
    });
  });

  group('BiosService.resolveBiosUri', () {
    test('falls back to systemUri/Bios when no Bios link is available',
        () async {
      final DioAdapter a = adapter();
      a.onGet(
        '/redfish/v1/Systems/437XR1138R2',
        (server) => server.reply(200, <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems/437XR1138R2',
          '@odata.type': '#ComputerSystem.v1_22_0.ComputerSystem',
        }),
      );
      final BiosService service = BiosService(
        client: clientWithAdapter(a),
        systemId: '437XR1138R2',
        systemResourceUri: '/redfish/v1/Systems/437XR1138R2',
      );
      expect(
        await service.resolveBiosUri(),
        '/redfish/v1/Systems/437XR1138R2/Bios',
      );
    });
  });
}
