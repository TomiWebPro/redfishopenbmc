import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/redfish/client/auth_manager.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';

/// Integration test against a real Redfish/BMC endpoint.
///
/// Skipped unless the following environment variables are supplied:
///   REDFISH_HOST, REDFISH_USER, REDFISH_PASS  (optionally REDFISH_PORT)
///
/// CI never sets these, so the suite stays green. Run locally with:
///   REDFISH_HOST=192.168.0.10 REDFISH_USER=root REDFISH_PASS=calvin \
///     flutter test test/redfish/client/client_integration_test.dart
void main() {
  test('real BMC login + service root (integration)', () async {
    final String host = const String.fromEnvironment('REDFISH_HOST');
    final String user = const String.fromEnvironment('REDFISH_USER');
    final String pass = const String.fromEnvironment('REDFISH_PASS');
    final int port =
        int.tryParse(const String.fromEnvironment('REDFISH_PORT')) ?? 443;

    if (host.isEmpty || user.isEmpty || pass.isEmpty) {
      markTestSkipped(
        'Set REDFISH_HOST/REDFISH_USER/REDFISH_PASS to run this integration '
        'test against a live Redfish endpoint.',
      );
      return;
    }

    final AuthManager manager = AuthManager(
      storage: InMemoryStorage(),
    );
    final Session session = await manager.login(
      'live',
      ConnectionProfile(host: host, port: port, username: user, password: pass),
    );
    expect(session.token, isNotEmpty);

    final RedfishClient client = manager.clientFor('live')!;
    final Map<String, dynamic> root = await client.getJson('/redfish/v1/');
    expect(root['@odata.id'], '/redfish/v1/');

    await manager.logout('live');
  });
}
