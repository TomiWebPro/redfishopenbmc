import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';

void main() {
  group('InMemoryStorage', () {
    late InMemoryStorage storage;

    setUp(() {
      storage = InMemoryStorage();
    });

    test('write and read round-trip', () async {
      await storage.write('token_bmc1', 'X-Auth-Token-123');
      expect(await storage.read('token_bmc1'), 'X-Auth-Token-123');
    });

    test('containsKey and delete', () async {
      await storage.write('k', 'v');
      expect(await storage.containsKey('k'), isTrue);
      await storage.delete('k');
      expect(await storage.containsKey('k'), isFalse);
      expect(await storage.read('k'), isNull);
    });

    test('readAll returns copy', () async {
      await storage.write('a', '1');
      await storage.write('b', '2');
      final map = await storage.readAll();
      expect(map, <String, String>{'a': '1', 'b': '2'});
    });

    test('deleteAll clears', () async {
      await storage.write('x', 'y');
      await storage.deleteAll();
      expect(await storage.readAll(), isEmpty);
    });

    test('overwrite value', () async {
      await storage.write('k', 'v1');
      await storage.write('k', 'v2');
      expect(await storage.read('k'), 'v2');
    });
  });
}
