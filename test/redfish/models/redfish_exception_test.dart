import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

void main() {
  group('RedfishException.isAuthError', () {
    test('classifies 401 and 403 as auth failures', () {
      expect(
        const RedfishException(message: 'unauthorized', statusCode: 401)
            .isAuthError,
        isTrue,
      );
      expect(
        const RedfishException(message: 'forbidden', statusCode: 403)
            .isAuthError,
        isTrue,
      );
    });

    test('does not classify missing/transient/other statuses as auth', () {
      expect(
        const RedfishException(message: 'missing', statusCode: 404).isAuthError,
        isFalse,
      );
      expect(
        const RedfishException(message: 'server', statusCode: 500).isAuthError,
        isFalse,
      );
      expect(
        const RedfishException(message: 'precondition', statusCode: 412)
            .isAuthError,
        isFalse,
      );
      expect(
        const RedfishException(message: 'network').isAuthError,
        isFalse,
      );
    });
  });

  group('redactUriCredentials (credential-leak audit #010)', () {
    test('passes null through unchanged', () {
      expect(redactUriCredentials(null), isNull);
    });

    test('returns a URI without userinfo byte-identical', () {
      final Uri plain =
          Uri.parse('https://bmc.example:8443/redfish/v1/Systems/1?x=1#frag');
      expect(redactUriCredentials(plain), same(plain));
    });

    test('strips userinfo but preserves every other URI component', () {
      final Uri redacted = redactUriCredentials(
        Uri.parse(
          'https://root:s3cret@bmc.example:8443/redfish/v1/Systems/1?x=1#frag',
        ),
      )!;
      expect(redacted.userInfo, isEmpty);
      expect(redacted.scheme, 'https');
      expect(redacted.host, 'bmc.example');
      expect(redacted.port, 8443);
      expect(redacted.path, '/redfish/v1/Systems/1');
      expect(redacted.query, 'x=1');
      expect(redacted.fragment, 'frag');
      expect(redacted.toString(), isNot(contains('s3cret')));
      expect(redacted.toString(), isNot(contains('root')));
    });

    test('strips percent-encoded userinfo', () {
      final Uri redacted = redactUriCredentials(
        Uri.parse('https://admin:p%40ss%3Aword@bmc.example/redfish/v1/'),
      )!;
      expect(redacted.userInfo, isEmpty);
      expect(redacted.toString(), isNot(contains('p%40ss')));
      expect(redacted.host, 'bmc.example');
    });
  });

  group('RedfishException URI redaction (credential-leak audit #010)', () {
    test('fromResponse strips userinfo from the captured URI', () {
      final Response<dynamic> response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/redfish/v1/'),
        statusCode: 500,
      );
      final RedfishException error = RedfishException.fromResponse(
        response,
        uri: Uri.parse('http://root:s3cret@bmc.example/redfish/v1/'),
      );
      expect(error.uri?.userInfo, isEmpty);
      expect(error.uri.toString(), isNot(contains('s3cret')));
      expect(error.toString(), isNot(contains('s3cret')));
      expect(error.uri.toString(), contains('bmc.example'));
    });

    test('fromDioException strips userinfo from response.realUri', () {
      // A redirect that lands on a userinfo-bearing URL: Dio derives
      // Response.realUri from RequestOptions.uri when there are no redirects.
      final Response<dynamic> response = Response<dynamic>(
        requestOptions: RequestOptions(
          path: 'http://root:s3cret@bmc.example/redfish/v1/',
        ),
        statusCode: 500,
      );
      final DioException dio = DioException(
        requestOptions: RequestOptions(path: '/redfish/v1/'),
        type: DioExceptionType.badResponse,
        response: response,
      );
      final RedfishException error = RedfishException.fromDioException(dio);
      expect(response.realUri.userInfo, isNotEmpty); // fixture is realistic
      expect(error.uri, isNotNull);
      expect(error.uri!.userInfo, isEmpty);
      expect(error.uri.toString(), isNot(contains('s3cret')));
      expect(error.toString(), isNot(contains('s3cret')));
    });

    test('fromDioException strips userinfo from an explicit uri override', () {
      final DioException dio = DioException(
        requestOptions: RequestOptions(path: '/redfish/v1/'),
        type: DioExceptionType.receiveTimeout,
      );
      final RedfishException error = RedfishException.fromDioException(
        dio,
        uri: Uri.parse('https://root:s3cret@bmc.example/redfish/v1/'),
      );
      expect(error.uri?.userInfo, isEmpty);
      expect(error.uri.toString(), isNot(contains('s3cret')));
    });
  });
}
