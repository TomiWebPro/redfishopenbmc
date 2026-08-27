import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/system_snapshot_fetcher.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';

/// Path-only matcher so the fetcher's traversal of `/redfish/v1/Systems` and the
/// per-system member URI is intercepted regardless of host.
class _PathMatcher extends HttpRequestMatcher {
  const _PathMatcher();
  @override
  bool matches(RequestOptions ongoingRequest, Request matcher) {
    final dynamic route = matcher.route;
    final String routeStr = route is String ? route : route.toString();
    final String path = ongoingRequest.path;
    return path == routeStr ||
        Uri.tryParse(path)?.path == routeStr ||
        path.endsWith(routeStr);
  }
}

void main() {
  group('fetchSystemSnapshot', () {
    test('maps a ComputerSystem member to a populated snapshot', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://bmc1:443'));
      final DioAdapter adapter = DioAdapter(dio: dio, matcher: const _PathMatcher());
      adapter.onGet(
        '/redfish/v1/Systems',
        (server) => server.reply(
          200,
          <String, dynamic>{
            'Members': <dynamic>[
              <String, dynamic>{'@odata.id': '/redfish/v1/Systems/1'},
            ],
          },
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        ),
      );
      adapter.onGet(
        '/redfish/v1/Systems/1',
        (server) => server.reply(
          200,
          <String, dynamic>{
            'Status': <String, dynamic>{'Health': 'OK'},
            'PowerState': 'On',
            'Manufacturer': 'Acme',
            'Model': 'Server-9',
            'SerialNumber': 'SN-XYZ',
          },
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        ),
      );

      final SystemSnapshot snap =
          await fetchSystemSnapshot(RedfishClient(profile: const ConnectionProfile(host: 'bmc1'), dio: dio));
      expect(snap.health, Health.ok);
      expect(snap.powerState, PowerState.on);
      expect(snap.manufacturer, 'Acme');
      expect(snap.model, 'Server-9');
      expect(snap.serialNumber, 'SN-XYZ');
      expect(snap.error, isNull);
    });

    test('returns unknown health when no ComputerSystems are reported', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://bmc1:443'));
      final DioAdapter adapter = DioAdapter(dio: dio, matcher: const _PathMatcher());
      adapter.onGet(
        '/redfish/v1/Systems',
        (server) => server.reply(
          200,
          <String, dynamic>{'Members': <dynamic>[]},
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        ),
      );

      final SystemSnapshot snap =
          await fetchSystemSnapshot(RedfishClient(profile: const ConnectionProfile(host: 'bmc1'), dio: dio));
      expect(snap.health, Health.unknown);
      expect(snap.error, 'No ComputerSystems reported');
    });

    test('degrades to unknown health on a transport error', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://bmc1:443'));
      final DioAdapter adapter = DioAdapter(dio: dio, matcher: const _PathMatcher());
      adapter.onGet(
        '/redfish/v1/Systems',
        (server) => server.reply(
          500,
          <String, dynamic>{'Message': 'boom'},
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        ),
      );

      final SystemSnapshot snap =
          await fetchSystemSnapshot(RedfishClient(profile: const ConnectionProfile(host: 'bmc1'), dio: dio));
      expect(snap.health, Health.unknown);
      expect(snap.error, isNotNull);
    });
  });
}
