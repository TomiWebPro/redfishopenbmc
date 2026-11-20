// EP-T13 (epic #009/#021): machine-checkable closeout of the dept-split contract
// itself. MULTI_DEPT.md hard rule 4 requires every queue item to carry exactly
// one `Dept:` (a single dept from the fixed set) and a non-empty `Verify:`
// command, but nothing failed closed when a future `queues/<dept>.md` item
// dropped one, duplicated `Dept:`, used an unknown dept, or left `Verify:`
// empty. This pure-Dart guard parses every unchecked `- [ ]` item in
// `queues/*.md` and fails closed on any such drift, so the dept ownership /
// verification contract cannot silently rot.
//
// The evaluator lives in this TEST-only file so it never scans or touches
// product code. It is comment-aware (the queues contain HTML comments whose
// prose mentions "Dept:/Verify:"), dependency-free, opens no network, uses no
// credentials, and never weakens production TLS. The RED→GREEN proof uses a
// temporary queue tree; the real-repo invariant pins the checked-in queues.
// CI already invokes this file via the existing whole-tree `flutter test
// --coverage` run, so no second workflow invocation is added.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The fixed single-writer department set from MULTI_DEPT.md §"Departments".
/// Adding a dept is an intentional, central edit here.
const Set<String> allowedDepartments = <String>{
  'rf-model',
  'rf-ui',
  'rf-service',
  'rf-tooling',
  'rf-platform',
  'rf-audit',
  'rf-ideate',
  'rf-check',
  'rf-gate',
};

/// Removes `<!-- ... -->` HTML comments, blanking their bytes but preserving
/// newlines so line numbers stay stable. Queue files contain comments that
/// say things like "Every item carries the mandatory Dept:/Verify: fields";
/// scanning them as fields would be a false positive, so a schema guard must
/// ignore comment prose exactly as it would ignore Dart comments.
String stripHtmlComments(String source) {
  final StringBuffer out = StringBuffer();
  int i = 0;
  final int n = source.length;
  while (i < n) {
    if (source.startsWith('<!--', i)) {
      final int end = source.indexOf('-->', i + 4);
      final int stop = end == -1 ? n : end + 3;
      for (int j = i; j < stop; j++) {
        out.write(source[j] == '\n' ? '\n' : ' ');
      }
      i = stop;
      continue;
    }
    out.write(source[i]);
    i++;
  }
  return out.toString();
}

/// One parsed unchecked `- [ ]` queue item. [dept] / [verify] hold the raw
/// trimmed values of every `Dept:` / `Verify:` field found in the item block.
class QueueItem {
  final String file;
  final int line;
  final String header;
  final List<String> dept;
  final List<String> verify;

  const QueueItem(this.file, this.line, this.header, this.dept, this.verify);
}

final RegExp _itemHeader = RegExp(r'^\s*- \[([ xX])\]');
final RegExp _sectionHeading = RegExp(r'^#{1,6}\s');
final RegExp _deptField = RegExp(r'^\s*Dept:\s*(.*)$');
final RegExp _verifyField = RegExp(r'^\s*Verify:\s*(.*)$');

/// Parses every unchecked item in one (comment-stripped) queue file. An item
/// block runs from its `- [ ]` header to the next list-item header or markdown
/// section heading; checked items are skipped. Field lines are indented
/// continuation lines within that block.
List<QueueItem> parseUncheckedItems(String file, String source) {
  final List<QueueItem> items = <QueueItem>[];
  QueueItem? current;
  final List<String> lines = source.split('\n');
  for (int idx = 0; idx < lines.length; idx++) {
    final String line = lines[idx];
    final RegExpMatch? header = _itemHeader.firstMatch(line);
    if (header != null) {
      if (current != null) {
        items.add(current);
      }
      final bool checked = header.group(1) != ' ';
      current = checked
          ? null
          : QueueItem(file, idx + 1, line.trim(), <String>[], <String>[]);
      continue;
    }
    if (current == null) {
      continue;
    }
    if (_sectionHeading.hasMatch(line)) {
      items.add(current);
      current = null;
      continue;
    }
    final RegExpMatch? dept = _deptField.firstMatch(line);
    if (dept != null) {
      current.dept.add(dept.group(1)!.trim());
      continue;
    }
    final RegExpMatch? verify = _verifyField.firstMatch(line);
    if (verify != null) {
      current.verify.add(verify.group(1)!.trim());
    }
  }
  if (current != null) {
    items.add(current);
  }
  return items;
}

/// Evaluates a map of queue file name → raw content. Returns a list of
/// fail-closed violations (empty means every unchecked item is well-formed).
List<String> evaluateQueueSchema(Map<String, String> queueSources) {
  final List<String> violations = <String>[];
  queueSources.forEach((String file, String raw) {
    final String source = stripHtmlComments(raw.replaceAll('\r', ''));
    for (final QueueItem item in parseUncheckedItems(file, source)) {
      final String at = '$file:${item.line} ${item.header}';
      if (item.dept.isEmpty) {
        violations.add('MISSING_DEPT: $at');
      } else if (item.dept.length > 1) {
        violations.add('MULTIPLE_DEPT: $at -> ${item.dept.join(" | ")}');
      } else if (!allowedDepartments.contains(item.dept.single)) {
        violations.add('BAD_DEPT: $at -> ${item.dept.single}');
      }
      if (item.verify.isEmpty) {
        violations.add('MISSING_VERIFY: $at');
      } else if (item.verify.every((String v) => v.isEmpty)) {
        violations.add('EMPTY_VERIFY: $at');
      }
    }
  });
  return violations;
}

/// Reads the real `queues/*.md` files from the repository root.
Map<String, String> readRealQueues() {
  final Map<String, String> out = <String, String>{};
  final Directory dir = Directory('queues');
  if (!dir.existsSync()) {
    return out;
  }
  for (final FileSystemEntity entity in dir.listSync()) {
    if (entity is File && entity.path.endsWith('.md')) {
      out[entity.path.replaceAll(r'\', '/')] = entity.readAsStringSync();
    }
  }
  return out;
}

/// A minimal valid queue item used by the pure + temp-root proofs.
const String validItem = '''
- [ ] EP-X1 A valid item: does the right thing.
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues);
              writes limited to `test/tool/**`.
''';

void main() {
  group('EP-T13 queue-item schema evaluator (pure)', () {
    test('allowed department set is the exact fixed MULTI_DEPT set', () {
      expect(allowedDepartments.length, 9);
      for (final String dept in <String>[
        'rf-model',
        'rf-ui',
        'rf-service',
        'rf-tooling',
        'rf-platform',
        'rf-audit',
        'rf-ideate',
        'rf-check',
        'rf-gate',
      ]) {
        expect(allowedDepartments.contains(dept), isTrue, reason: dept);
      }
      expect(allowedDepartments.contains('rf-unknown'), isFalse);
    });

    test('HTML comments are blanked but newlines are preserved', () {
      const String src = 'a <!-- Dept: rf-fake\nVerify: --> b\nDept: rf-ui\n';
      final String stripped = stripHtmlComments(src);
      expect(stripped, contains('a '));
      expect(stripped, contains('b\n'));
      expect(stripped, contains('Dept: rf-ui'));
      expect(stripped.contains('rf-fake'), isFalse);
      // All three real newlines are kept (one inside the comment, two after).
      expect('\n'.allMatches(stripped).length, 3);
    });

    test('a well-formed item is clean', () {
      expect(
          evaluateQueueSchema(<String, String>{'queues/tooling.md': validItem}),
          isEmpty);
    });

    test('missing Dept fails closed', () {
      const String bad = '- [ ] EP-X1 Item\n      Verify: `flutter test`\n';
      expect(
        evaluateQueueSchema(<String, String>{'queues/tooling.md': bad})
            .any((String v) => v.startsWith('MISSING_DEPT:')),
        isTrue,
      );
    });

    test('multiple Dept fields fail closed and name the offenders', () {
      const String bad = '''
- [ ] EP-X1 Item
      Dept: rf-ui
      Dept: rf-model
      Verify: `flutter test`
''';
      final List<String> violations =
          evaluateQueueSchema(<String, String>{'queues/ui.md': bad});
      expect(
          violations.any((String v) => v.startsWith('MULTIPLE_DEPT:')), isTrue);
      expect(violations.single, contains('queues/ui.md:1'));
      expect(violations.single, contains('rf-ui | rf-model'));
    });

    test('an out-of-set Dept fails closed', () {
      const String bad = '''
- [ ] EP-X1 Item
      Dept: rf-evil
      Verify: `flutter test`
''';
      expect(
        evaluateQueueSchema(<String, String>{'queues/ui.md': bad}).any(
            (String v) => v.startsWith('BAD_DEPT:') && v.contains('rf-evil')),
        isTrue,
      );
    });

    test('missing Verify fails closed', () {
      const String bad = '''
- [ ] EP-X1 Item
      Dept: rf-ui
''';
      expect(
        evaluateQueueSchema(<String, String>{'queues/ui.md': bad})
            .any((String v) => v.startsWith('MISSING_VERIFY:')),
        isTrue,
      );
    });

    test('empty Verify fails closed', () {
      const String bad = '''
- [ ] EP-X1 Item
      Dept: rf-ui
      Verify:
''';
      expect(
        evaluateQueueSchema(<String, String>{'queues/ui.md': bad})
            .any((String v) => v.startsWith('EMPTY_VERIFY:')),
        isTrue,
      );
    });

    test('Dept prose inside an HTML comment is not counted as a field', () {
      // Mirrors the real queues/platform.md footer comment that says
      // "Every item carries the mandatory Dept:/Verify: fields".
      const String src = '''
<!-- Every item carries the mandatory Dept:/Verify: fields (hard rule 4). -->
- [ ] EP-X1 Item
      Dept: rf-platform
      Verify: `flutter test`
''';
      expect(evaluateQueueSchema(<String, String>{'queues/platform.md': src}),
          isEmpty);
    });

    test('checked items and section headings close the preceding block', () {
      const String src = '''
- [x] EP-DONE Landed item with no fields at all.

## Next section

- [ ] EP-X1 Item
      Dept: rf-service
      Verify: `flutter test`
''';
      final List<QueueItem> items =
          parseUncheckedItems('queues/service.md', stripHtmlComments(src));
      expect(items.length, 1);
      expect(items.single.header, contains('EP-X1'));
      expect(evaluateQueueSchema(<String, String>{'queues/service.md': src}),
          isEmpty);
    });

    test('one malformed item among many names the offending file and line', () {
      const String src = '''
- [ ] EP-X1 Good item
      Dept: rf-ui
      Verify: `flutter test`
- [ ] EP-X2 Bad item
      Dept: rf-nope
      Verify: `flutter test`
''';
      final List<String> violations =
          evaluateQueueSchema(<String, String>{'queues/ui.md': src});
      expect(violations.length, 1);
      expect(violations.single, contains('queues/ui.md:4'));
    });
  });

  group('EP-T13 RED→GREEN guard proof (temporary queue tree)', () {
    test(
        'valid tree is clean; each malformation fails closed; restore is clean',
        () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t13_queue_');
      final File queue = File(
        '${temp.path}${Platform.pathSeparator}queues${Platform.pathSeparator}'
        'tooling.md',
      );
      try {
        queue.parent.createSync(recursive: true);
        queue.writeAsStringSync(validItem);
        Map<String, String> read() => <String, String>{
              'queues/tooling.md': queue.readAsStringSync(),
            };

        // GREEN: well-formed item.
        expect(evaluateQueueSchema(read()), isEmpty);

        // RED 1: missing Dept.
        queue.writeAsStringSync(
            '- [ ] EP-X1 Item\n      Verify: `flutter test`\n');
        expect(
          evaluateQueueSchema(read())
              .any((String v) => v.startsWith('MISSING_DEPT:')),
          isTrue,
        );

        // RED 2: duplicate Dept.
        queue.writeAsStringSync(validItem.replaceFirst(
          '      Dept: rf-tooling\n',
          '      Dept: rf-tooling\n      Dept: rf-ui\n',
        ));
        expect(
          evaluateQueueSchema(read())
              .any((String v) => v.startsWith('MULTIPLE_DEPT:')),
          isTrue,
        );

        // RED 3: unknown dept.
        queue
            .writeAsStringSync(validItem.replaceFirst('rf-tooling', 'rf-evil'));
        expect(
          evaluateQueueSchema(read())
              .any((String v) => v.startsWith('BAD_DEPT:')),
          isTrue,
        );

        // RED 4: empty Verify.
        queue.writeAsStringSync(validItem.replaceFirst(
          '      Verify: `flutter test test/tool/ && flutter analyze` (0 issues);',
          '      Verify:',
        ));
        expect(
          evaluateQueueSchema(read())
              .any((String v) => v.startsWith('EMPTY_VERIFY:')),
          isTrue,
        );

        // GREEN again once restored.
        queue.writeAsStringSync(validItem);
        expect(evaluateQueueSchema(read()), isEmpty);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('EP-T13 real repository invariant', () {
    test('every unchecked queue item carries one valid Dept and a Verify', () {
      final Map<String, String> queues = readRealQueues();
      expect(queues.length, 5, reason: 'expected the five dept queue files');
      final List<QueueItem> all = <QueueItem>[];
      queues.forEach((String file, String raw) {
        all.addAll(parseUncheckedItems(file, stripHtmlComments(raw)));
      });
      // Guard liveness: an empty parse must never silently pass.
      expect(all.length, greaterThanOrEqualTo(15),
          reason: 'parser saw too few unchecked items');
      final List<String> violations = evaluateQueueSchema(queues);
      expect(
        violations,
        isEmpty,
        reason: 'queue schema drift: ${violations.join(", ")}',
      );
    });
  });
}
