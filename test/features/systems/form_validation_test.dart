import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/systems/views/system_profile_form.dart';

void main() {
  group('validateHost', () {
    test('accepts IPv4 and hostnames', () {
      expect(validateHost('192.168.1.10'), isNull);
      expect(validateHost('bmc.example.com'), isNull);
      expect(validateHost('localhost'), isNull);
    });

    test('rejects empty and invalid values', () {
      expect(validateHost(null), isNotNull);
      expect(validateHost(''), isNotNull);
      expect(validateHost('bad host!'), isNotNull);
      expect(validateHost('host..com'), isNotNull);
      expect(validateHost('http://x'), isNotNull);
    });
  });

  group('validatePort', () {
    test('accepts in-range ports', () {
      expect(validatePort('443'), isNull);
      expect(validatePort('8443'), isNull);
      expect(validatePort('65535'), isNull);
      expect(validatePort('1'), isNull);
    });

    test('rejects out-of-range or non-numeric ports', () {
      expect(validatePort(null), isNotNull);
      expect(validatePort(''), isNotNull);
      expect(validatePort('0'), isNotNull);
      expect(validatePort('70000'), isNotNull);
      expect(validatePort('abc'), isNotNull);
    });
  });
}
