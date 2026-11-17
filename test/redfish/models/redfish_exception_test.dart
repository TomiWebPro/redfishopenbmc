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
}
