// ignore_for_file: prefer_const_constructors
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:redfishopenbmc/features/overview/models/boot_settings.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/settings_service.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Matches mock routes by **method + path**, and additionally validates the
/// expected request body / headers when the rule declares them.
///
/// The library's default `FullHttpRequestMatcher` requires an exact header
/// match, which Dio's auto-added headers (Accept, OData-Version,
/// content-type) break; a bare path matcher would let a GET match a PATCH
/// rule (the handler picks the LAST matching rule). This matcher compares the
/// method first, then the path (suffix-tolerant like the #002 helper), then —
/// when the registered rule carries `data`/`headers` — those expectations.
class _MethodPathMatcher extends HttpRequestMatcher {
  const _MethodPathMatcher();

  @override
  bool matches(RequestOptions ongoingRequest, Request matcher) {
    // Method must match first (GET rule never answers a PATCH and vice versa).
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

    // When the rule declares an expected body, require it to match (map
    // subset equality — Dio may add nothing here, but the JSON maps must be
    // equal). A mismatch means "no rule for this request" → the adapter
    // fails the test with its missing-mock AssertionError.
    if (matcher.data != null) {
      final dynamic actual = ongoingRequest.data;
      if (actual is! Map || !_mapContains(actual, matcher.data as Map)) {
        return false;
      }
    }

    // When the rule declares expected headers, require each to be present.
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
        if (!_mapContains(actualValue, expectedValue)) {
          return false;
        }
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

RedfishClient clientWithAdapter(DioAdapter adapter) => RedfishClient(
      profile: const ConnectionProfile(host: 'bmc1.local', name: 'bmc1'),
      dio: adapter.dio,
    );

/// Builds a ComputerSystem resource body carrying the served Boot block
/// (mockup `437XR1138R2` shape) + an optional @odata.etag.
Map<String, dynamic> computerSystemBody({
  String uri = '/redfish/v1/Systems/system',
  String led = 'Off',
  String bootTarget = 'Pxe',
  String? etag,
}) =>
    <String, dynamic>{
      '@odata.id': uri,
      '@odata.type': '#ComputerSystem.v1_22_0.ComputerSystem',
      'Id': 'system',
      'Name': 'System',
      'IndicatorLED': led,
      'Boot': <String, dynamic>{
        'BootSourceOverrideEnabled': 'Once',
        'BootSourceOverrideMode': 'UEFI',
        'BootSourceOverrideTarget': bootTarget,
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
      if (etag != null) '@odata.etag': etag,
    };

SystemFeatures featuresWithSystem({String uri = '/redfish/v1/Systems/system'}) {
  return SystemFeatures(
    systemId: 'bmc1',
    raw: <String, dynamic>{uri: computerSystemBody(uri: uri)},
  );
}

void main() {
  group('SystemSettingsService — fetchBootSettings', () {
    test('parses the Boot block from the resolved system resource', () async {
      final DioAdapter a = adapter();
      a.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(200, computerSystemBody()),
      );
      final SystemSettingsService service = SystemSettingsService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
        features: featuresWithSystem(),
      );

      final BootSettings s = await service.fetchBootSettings();
      expect(s.target, 'Pxe');
      expect(s.enabled, 'Once');
      expect(s.hasAllowableTargets, isTrue);
    });

    test('surfaces a friendly not-connected error', () async {
      final SystemSettingsService service =
          SystemSettingsService(client: null, systemId: 'bmc1');
      await expectLater(
        service.fetchBootSettings(),
        throwsA(
          isA<RedfishException>().having((RedfishException e) => e.errorCode,
              'errorCode', 'Base.1.0.NotConnected'),
        ),
      );
    });

    test('rethrows RedfishException transport failures', () async {
      final DioAdapter a = adapter();
      a.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(
          403,
          <String, dynamic>{
            'error': <String, dynamic>{'code': 'Base.1.0.Ins'}
          },
        ),
      );
      final SystemSettingsService service = SystemSettingsService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
        features: featuresWithSystem(),
      );
      await expectLater(
        service.fetchBootSettings(),
        throwsA(isA<RedfishException>()),
      );
    });
  });

  group('SystemSettingsService — setIndicatorLed', () {
    test('PATCHes the exact body + carries the @odata.etag as If-Match',
        () async {
      final DioAdapter a = adapter();
      a.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(200, computerSystemBody(etag: 'abc123')),
      );
      // The rule declares the exact body + If-Match header; a request with a
      // different body/header fails the missing-mock assertion → the test
      // proves the service sent exactly this PATCH.
      a.onPatch(
        '/redfish/v1/Systems/system',
        (server) => server.reply(204, null),
        data: <String, dynamic>{'IndicatorLED': 'Lit'},
        headers: <String, dynamic>{'If-Match': '"abc123"'},
      );

      final SystemSettingsService service = SystemSettingsService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
        features: featuresWithSystem(),
      );
      final Map<String, dynamic> result =
          await service.setIndicatorLed(IndicatorLed.lit);
      expect(result, isEmpty); // normalized 204 → empty placeholder map
    });

    test('rejects Unknown locally before any request (schema-deprecated)',
        () async {
      final DioAdapter a = adapter();
      // No onPatch rule registered: a PATCH attempt would fail the
      // missing-mock assertion, proving the invalid enum is never sent.
      final SystemSettingsService service = SystemSettingsService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
        features: featuresWithSystem(),
      );
      await expectLater(
        service.setIndicatorLed(IndicatorLed.unknown),
        throwsA(
          isA<RedfishException>().having(
            (RedfishException e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });

    test('surfaces a friendly not-connected error', () async {
      final SystemSettingsService service =
          SystemSettingsService(client: null, systemId: 'bmc1');
      await expectLater(
        service.setIndicatorLed(IndicatorLed.lit),
        throwsA(
          isA<RedfishException>().having((RedfishException e) => e.errorCode,
              'errorCode', 'Base.1.0.NotConnected'),
        ),
      );
    });
  });

  group('SystemSettingsService — setBootOverride', () {
    test('PATCHes Boot target + enabled with the etag precondition', () async {
      final DioAdapter a = adapter();
      a.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(200, computerSystemBody(etag: 'boot-etag')),
      );
      a.onPatch(
        '/redfish/v1/Systems/system',
        (server) => server.reply(204, null),
        data: <String, dynamic>{
          'Boot': <String, dynamic>{
            'BootSourceOverrideTarget': 'Cd',
            'BootSourceOverrideEnabled': 'Once',
          },
        },
        headers: <String, dynamic>{'If-Match': '"boot-etag"'},
      );

      final SystemSettingsService service = SystemSettingsService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
        features: featuresWithSystem(),
      );
      await service.setBootOverride(target: 'Cd', enabled: 'Once');
    });

    test('defaults enabled to Once', () async {
      final DioAdapter a = adapter();
      a.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(200, computerSystemBody()),
      );
      a.onPatch(
        '/redfish/v1/Systems/system',
        (server) => server.reply(204, null),
        data: <String, dynamic>{
          'Boot': <String, dynamic>{
            'BootSourceOverrideTarget': 'Usb',
            'BootSourceOverrideEnabled': 'Once',
          },
        },
      );

      final SystemSettingsService service = SystemSettingsService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
        features: featuresWithSystem(),
      );
      await service.setBootOverride(target: 'Usb');
    });

    test('rejects a target not in the advertised allow-list locally', () async {
      final DioAdapter a = adapter();
      a.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(200, computerSystemBody()),
      );
      // No onPatch rule: a PATCH would fail the missing-mock assertion.
      final SystemSettingsService service = SystemSettingsService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
        features: featuresWithSystem(),
      );
      await expectLater(
        service.setBootOverride(target: 'Bogus'),
        throwsA(
          isA<RedfishException>()
              .having((RedfishException e) => e.statusCode, 'statusCode', 400)
              .having((RedfishException e) => e.errorCode, 'errorCode',
                  'Base.1.0.PropertyValueNotInList'),
        ),
      );
    });

    test('refuses when the BMC publishes no allow-list (never guess)',
        () async {
      final DioAdapter a = adapter();
      a.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(200, <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems/system',
          'Boot': <String, dynamic>{
            'BootSourceOverrideEnabled': 'Once',
            'BootSourceOverrideTarget': 'Pxe',
          },
        }),
      );
      // No onPatch rule: a PATCH would fail the missing-mock assertion.
      final SystemSettingsService service = SystemSettingsService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
        features: featuresWithSystem(),
      );
      await expectLater(
        service.setBootOverride(target: 'Pxe'),
        throwsA(
          isA<RedfishException>().having(
            (RedfishException e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });

    test('rejects an invalid enabled state locally', () async {
      final DioAdapter a = adapter();
      a.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(200, computerSystemBody()),
      );
      final SystemSettingsService service = SystemSettingsService(
        client: clientWithAdapter(a),
        systemId: 'bmc1',
        features: featuresWithSystem(),
      );
      await expectLater(
        service.setBootOverride(target: 'Pxe', enabled: 'Sometimes'),
        throwsA(
          isA<RedfishException>().having(
            (RedfishException e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });

    test('surfaces a friendly not-connected error', () async {
      final SystemSettingsService service =
          SystemSettingsService(client: null, systemId: 'bmc1');
      await expectLater(
        service.setBootOverride(target: 'Pxe'),
        throwsA(
          isA<RedfishException>().having((RedfishException e) => e.errorCode,
              'errorCode', 'Base.1.0.NotConnected'),
        ),
      );
    });
  });
}
