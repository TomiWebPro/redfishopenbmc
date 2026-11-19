// Pure-Dart tests for the shared `MaxConcurrentSessions` parser (issue #009).
//
// `kvmSessionLimit` is the single source of truth for both KVM views' session
// limit. These tests pin the tolerant-but-spec-valid contract so the console
// card and capability card can never drift apart again.
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_session_limit.dart';

void main() {
  group('kvmSessionLimit', () {
    test('accepts a spec-valid int and zero', () {
      expect(kvmSessionLimit(4), 4);
      expect(kvmSessionLimit(0), 0);
    });

    test('tolerates an integer-valued JSON double (BMC serializer "4.0")', () {
      // dart:convert decodes a JSON number with a decimal point to a double;
      // some BMCs emit that form for integer-valued schema fields.
      expect(kvmSessionLimit(4.0), 4);
      expect(kvmSessionLimit(0.0), 0);
      expect(kvmSessionLimit(2.0e1), 20);
    });

    test('rejects a fractional or non-finite double', () {
      expect(kvmSessionLimit(2.5), isNull);
      expect(kvmSessionLimit(double.nan), isNull);
      expect(kvmSessionLimit(double.infinity), isNull);
      expect(kvmSessionLimit(double.negativeInfinity), isNull);
    });

    test('rejects a double too large to convert to int exactly', () {
      // 2^53 + 2 is not exactly representable; accepting it could silently
      // change the reported limit, so it is surfaced as unreported.
      expect(kvmSessionLimit(9007199254740994.0), isNull);
    });

    test('accepts numeric strings in int or integral-double form', () {
      expect(kvmSessionLimit('4'), 4);
      expect(kvmSessionLimit('  4  '), 4);
      expect(kvmSessionLimit('4.0'), 4);
      expect(kvmSessionLimit('+2'), 2);
    });

    test('rejects negative, blank, non-numeric and wrong-typed values', () {
      expect(kvmSessionLimit(-1), isNull);
      expect(kvmSessionLimit(-1.0), isNull);
      expect(kvmSessionLimit('-5'), isNull);
      expect(kvmSessionLimit(''), isNull);
      expect(kvmSessionLimit('   '), isNull);
      expect(kvmSessionLimit('abc'), isNull);
      expect(kvmSessionLimit(null), isNull);
      expect(kvmSessionLimit(true), isNull);
      expect(kvmSessionLimit(<int>[4]), isNull);
      expect(kvmSessionLimit(<String, dynamic>{'v': 4}), isNull);
    });
  });
}
