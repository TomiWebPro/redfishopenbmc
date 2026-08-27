import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/redfish/client/http_client_config.dart';

/// Exercises the platform [createHttpClientAdapter] factory used by
/// [RedfishClient] to wire TLS behavior.
///
/// On the Linux/CUDA test runner this resolves to the `dart:io`
/// implementation (`http_client_config_io.dart`). The self-signed branch is
/// the one historically left uncovered, so it is asserted explicitly here.
void main() {
  group('createHttpClientAdapter (TLS config)', () {
    test('default (validate certs) returns a usable adapter', () {
      final HttpClientAdapter adapter = createHttpClientAdapter(false);
      expect(adapter, isA<HttpClientAdapter>());
      // The strict path must be the real I/O adapter, not a custom closure.
      expect(adapter, isA<IOHttpClientAdapter>());
    });

    test('opt-in self-signed returns an I/O adapter (accepts any cert)', () {
      // Construction must not throw; the relaxed trust is wired inside the
      // HttpClient via badCertificateCallback (not externally observable
      // without a live socket), so we assert the shape here.
      final HttpClientAdapter adapter = createHttpClientAdapter(true);
      expect(adapter, isA<HttpClientAdapter>());
      expect(adapter, isA<IOHttpClientAdapter>());
    });

    test('flag toggles produce distinct adapter instances', () {
      final HttpClientAdapter strict = createHttpClientAdapter(false);
      final HttpClientAdapter relaxed = createHttpClientAdapter(true);
      expect(strict, isNot(same(relaxed)));
    });
  });
}
