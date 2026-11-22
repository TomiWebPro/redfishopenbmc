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
//
// EP-T24 (epic #009/#021): the EP-T13 schema check only proved a `Verify:`
// field was non-empty. A command naming a dangling / placeholder / typo'd
// suite still passed, so a stale queue item could point a builder at a
// non-existent test/tool path. This guard additionally requires every
// unchecked item's verify command to name at least one REPO-EXISTING target
// path. Accepted target roots are `test/`, `tool/`, `test_integration/` and
// `lib/`: the first three are the suite/script roots, while `lib/` is needed
// because the human-gated EP-P1 item legitimately verifies a doc's existence
// with `test -f lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md`. Existence is
// checked with an injectable predicate so the RED→GREEN proof needs no real
// queue-file mutation (safe under concurrent dept-agent edits).
//
// EP-T25 (epic #009/#021): EP-T13 pins exactly one valid `Dept:` and EP-T24
// pins that the verify command names repo-existing paths, but NEITHER pins
// MULTI_DEPT.md hard rule 1 (single-writer path ownership): an item whose
// declared write-scope / verify command names a product `lib/**` path owned
// by a DIFFERENT dept still passed both guards, silently breaking the
// one-writer contract. This guard additionally requires every product `lib/`
// path named in an unchecked item to fall inside that item's `Dept:` owned
// product-path set (rf-tooling / rf-ideate / rf-audit / rf-check / rf-gate
// own no product lib). Shared `test/**` / `tool/**` / `test_integration/**`
// paths stay exempt. Ownership is injectable so the real-repo invariant can
// prove non-vacuity without mutating concurrently-edited queue files.
//
// EP-T27 (epic #009/#021): EP-T13 pins exactly one VALID `Dept:`, EP-T24 pins
// the verify target paths and EP-T25 pins that named product `lib/**` paths
// are owned by that dept — but NONE of them checks that the declared `Dept:`
// matches the queue FILE the item is filed in. MULTI_DEPT.md hard rule 1
// (single-writer routing) requires `queues/platform.md` → `rf-platform`,
// `model.md` → `rf-model`, `ui.md` → `rf-ui`, `service.md` → `rf-service`,
// `tooling.md` → `rf-tooling`; a mis-filed item (e.g. `Dept: rf-model` inside
// ui.md) passes all three earlier guards yet is handed to the wrong worktree.
// This guard fails closed on that drift. The expected-dept map is injectable
// so the RED→GREEN proof needs no real queue-file mutation (dept files are
// being edited concurrently) and the real-repo invariant can prove non-vacuity.

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

/// Product `lib/**` write-scope owned by each dept, from MULTI_DEPT.md
/// §"Departments" (paths normalised: no trailing glob / slash). rf-service's
/// "controllers/providers" ownership is represented by the concrete
/// controller/provider files in this app; adding a new owned product path is
/// an intentional central edit here. Depts with no product `lib/` ownership
/// map to an empty list, so ANY product path they name fails closed.
const Map<String, List<String>> deptOwnedProductPaths = <String, List<String>>{
  'rf-model': <String>['lib/features/kvm/models', 'lib/redfish/discovery'],
  'rf-ui': <String>['lib/features/kvm/views', 'lib/features/systems'],
  'rf-service': <String>[
    'lib/features/kvm/kvm_service.dart',
    'lib/features/kvm/kvm_controller.dart',
    'lib/redfish/client',
  ],
  'rf-platform': <String>['lib/features/kvm/platform'],
  'rf-tooling': <String>[],
  'rf-audit': <String>[],
  'rf-ideate': <String>[],
  'rf-check': <String>[],
  'rf-gate': <String>[],
};

/// The dept encoded in each checked-in queue FILE NAME from MULTI_DEPT.md
/// §"Departments" (single-writer routing, hard rule 1). Only the five real
/// dept queue files are mapped; an unknown file name skips the routing check
/// (the real-repo invariant separately asserts exactly those five files).
/// Injectable so RED→GREEN and non-vacuity need no real queue-file mutation.
const Map<String, String> deptForQueueFile = <String, String>{
  'queues/platform.md': 'rf-platform',
  'queues/model.md': 'rf-model',
  'queues/ui.md': 'rf-ui',
  'queues/service.md': 'rf-service',
  'queues/tooling.md': 'rf-tooling',
};

/// True when [path] (already normalised) is at or below one of [owned] prefixes.
/// A prefix matches itself or a descendant only on a `/` boundary, so
/// `lib/features/kvm/models` never accepts `lib/features/kvm/models_extra`.
bool pathIsOwned(String path, List<String> owned) => owned.any(
      (String prefix) => path == prefix || path.startsWith('$prefix/'),
    );

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

/// Injectable path-existence predicate. The real-repo invariant uses the
/// filesystem; the RED→GREEN proof injects a controlled set so no real queue
/// file has to be mutated (they are being edited concurrently by dept agents).
typedef PathExists = bool Function(String path);

bool _repoPathExists(String path) =>
    FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

/// Strips trailing glob / directory markers so a command's `test/tool/**`
/// normalises to the real base directory `test/tool` for the existence check.
String normaliseVerifyTarget(String token) {
  String t = token;
  while (true) {
    if (t.endsWith('/**')) {
      t = t.substring(0, t.length - 3);
    } else if (t.endsWith('/*')) {
      t = t.substring(0, t.length - 2);
    } else if (t.endsWith('/')) {
      t = t.substring(0, t.length - 1);
    } else {
      break;
    }
  }
  return t;
}

final RegExp _verifyPathToken = RegExp(
    r'(?:^|[^A-Za-z0-9_./-])((?:test_integration|test|tool|lib)/[A-Za-z0-9_.\-/*]+)');

/// Extracts normalised repo-relative target paths named in a verify command.
/// `flutter analyze` alone names none; `flutter test test/tool/x_test.dart`
/// names `test/tool/x_test.dart`; `test -f lib/x.md` names `lib/x.md`.
List<String> extractVerifyTargets(String command) {
  final List<String> out = <String>[];
  for (final RegExpMatch m in _verifyPathToken.allMatches(command)) {
    final String path = normaliseVerifyTarget(m.group(1)!);
    if (path.isNotEmpty && !out.contains(path)) {
      out.add(path);
    }
  }
  return out;
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
    } else if (current.verify.isNotEmpty &&
        current.verify.last.isNotEmpty &&
        line.startsWith(RegExp(r'\s'))) {
      // A wrapped `Verify:` field continues on the following indented lines.
      // Capture them so path tokens on a later line (e.g. EP-T2's `tool/**`)
      // are not silently dropped and mistaken for a missing target (EP-T24).
      final String continuation = line.trim();
      if (continuation.isNotEmpty) {
        current.verify[current.verify.length - 1] =
            '${current.verify.last} $continuation';
      }
    }
  }
  if (current != null) {
    items.add(current);
  }
  return items;
}

/// Evaluates a map of queue file name → raw content. Returns a list of
/// fail-closed violations (empty means every unchecked item is well-formed).
List<String> evaluateQueueSchema(
  Map<String, String> queueSources, {
  PathExists pathExists = _repoPathExists,
  Map<String, List<String>> ownedPaths = deptOwnedProductPaths,
  Map<String, String> deptForFile = deptForQueueFile,
}) {
  final List<String> violations = <String>[];
  queueSources.forEach((String file, String raw) {
    final String source = stripHtmlComments(raw.replaceAll('\r', ''));
    for (final QueueItem item in parseUncheckedItems(file, source)) {
      final String at = '$file:${item.line} ${item.header}';
      bool deptIsValid = false;
      if (item.dept.isEmpty) {
        violations.add('MISSING_DEPT: $at');
      } else if (item.dept.length > 1) {
        violations.add('MULTIPLE_DEPT: $at -> ${item.dept.join(" | ")}');
      } else if (!allowedDepartments.contains(item.dept.single)) {
        violations.add('BAD_DEPT: $at -> ${item.dept.single}');
      } else {
        deptIsValid = true;
        // EP-T27: MULTI_DEPT.md hard rule 1 — the declared dept must route to
        // the queue FILE the item lives in. Unknown file names are skipped
        // (only the five real dept queue files carry a canonical dept).
        final String? expected = deptForFile[file];
        if (expected != null && item.dept.single != expected) {
          violations.add(
            'DEPT_QUEUE_MISMATCH: $at -> file=$file declares '
            'dept=${item.dept.single}, expected $expected',
          );
        }
      }
      if (item.verify.isEmpty) {
        violations.add('MISSING_VERIFY: $at');
      } else if (item.verify.every((String v) => v.isEmpty)) {
        violations.add('EMPTY_VERIFY: $at');
      } else {
        // EP-T24: a non-empty command must name at least one repo-existing
        // target path, so a dangling / placeholder / typo'd suite fails closed.
        final List<String> targets =
            extractVerifyTargets(item.verify.join(' '));
        if (targets.isEmpty) {
          violations.add('VERIFY_NO_TARGET: $at');
        } else if (!targets.any(pathExists)) {
          violations
              .add('VERIFY_DANGLING_TARGET: $at -> ${targets.join(" | ")}');
        }
        // EP-T25: MULTI_DEPT hard rule 1 — any product `lib/**` path named in
        // the write-scope / verify command must sit inside this dept's owned
        // product-path set. Shared test/tool paths are exempt. Only evaluated
        // when the item has exactly one valid dept (ownership is undefined
        // otherwise, and the dept schema violation is already reported).
        if (deptIsValid) {
          final String dept = item.dept.single;
          final List<String> owned = ownedPaths[dept] ?? const <String>[];
          for (final String productPath in targets.where(
            (String p) => p.startsWith('lib/'),
          )) {
            if (!pathIsOwned(productPath, owned)) {
              violations.add(
                'DEPT_PATH_OWNERSHIP: $at -> dept=$dept names foreign '
                'product path $productPath',
              );
            }
          }
        }
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
      Verify: `flutter test test/tool/`
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
      Verify: `flutter test test/tool/`
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
      Verify: `flutter test test/tool/`
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
      Verify: `flutter test test/tool/`
- [ ] EP-X2 Bad item
      Dept: rf-nope
      Verify: `flutter test test/tool/`
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

  group('EP-T24 verify-target evaluator (pure)', () {
    const Set<String> existing = <String>{
      'test/tool',
      'test/tool/queue_item_schema_guard_test.dart',
      'test/features/kvm',
      'tool/emulator/run_tests.sh',
      'test_integration/emulator/foo.dart',
      'lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md',
    };
    bool exists(String path) => existing.contains(path);

    test('extractVerifyTargets finds and normalises repo path tokens', () {
      expect(extractVerifyTargets('flutter analyze'), isEmpty);
      expect(
        extractVerifyTargets(
            'flutter test test/tool/queue_item_schema_guard_test.dart && flutter analyze'),
        <String>['test/tool/queue_item_schema_guard_test.dart'],
      );
      expect(
        extractVerifyTargets(
            'flutter test test/features/kvm/** && flutter analyze'),
        <String>['test/features/kvm'],
      );
      expect(extractVerifyTargets('bash tool/emulator/run_tests.sh'),
          <String>['tool/emulator/run_tests.sh']);
      expect(
        extractVerifyTargets(
            'test -f lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md && flutter analyze'),
        <String>['lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md'],
      );
      expect(
        extractVerifyTargets('flutter test test_integration/emulator/foo.dart'),
        <String>['test_integration/emulator/foo.dart'],
      );
      expect(
        extractVerifyTargets(
            'flutter test test/tool/a_test.dart test/tool/a_test.dart test/tool/b_test.dart'),
        <String>['test/tool/a_test.dart', 'test/tool/b_test.dart'],
      );
      // A word merely ending in a root name is not a path token.
      expect(
          extractVerifyTargets(
              'flutter test mylib/foo.dart && flutter analyze'),
          isEmpty);
    });

    test('a verify command naming no repo path fails closed', () {
      final List<String> v = evaluateQueueSchema(
        <String, String>{
          'queues/ui.md':
              '- [ ] EP-X24 Item\n      Dept: rf-ui\n      Verify: `flutter analyze`\n',
        },
        pathExists: exists,
      );
      expect(v.any((String s) => s.startsWith('VERIFY_NO_TARGET:')), isTrue);
    });

    test("a dangling / typo'd verify target fails closed", () {
      final List<String> v = evaluateQueueSchema(
        <String, String>{
          'queues/ui.md':
              '- [ ] EP-X24 Item\n      Dept: rf-ui\n      Verify: `flutter test test/tool/placeholder_typo_test.dart`\n',
        },
        pathExists: exists,
      );
      expect(
        v.any((String s) =>
            s.startsWith('VERIFY_DANGLING_TARGET:') &&
            s.contains('placeholder_typo_test.dart')),
        isTrue,
      );
    });

    test('one existing target among dangling ones is clean', () {
      expect(
        evaluateQueueSchema(
          <String, String>{
            'queues/ui.md':
                '- [ ] EP-X24 Item\n      Dept: rf-ui\n      Verify: `flutter test test/tool/nope_test.dart test/tool/queue_item_schema_guard_test.dart`\n',
          },
          pathExists: exists,
        ),
        isEmpty,
      );
    });

    test('glob targets and lib doc-existence checks are accepted', () {
      for (final String command in <String>[
        'flutter test test/features/kvm/** && flutter analyze',
        'test -f lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md && flutter analyze',
        'flutter test test_integration/emulator/foo.dart && flutter analyze',
      ]) {
        expect(
          evaluateQueueSchema(
            <String, String>{
              // The lib doc-existence command is EP-P1's shape, owned by
              // rf-platform; the other two commands name only shared test
              // paths and are valid for any dept.
              'queues/platform.md':
                  '- [ ] EP-X24 Item\n      Dept: rf-platform\n      Verify: `$command`\n',
            },
            pathExists: exists,
          ),
          isEmpty,
          reason: command,
        );
      }
    });

    test('missing or empty Verify reports only its schema violation', () {
      final List<String> missing = evaluateQueueSchema(
        <String, String>{
          'queues/ui.md': '- [ ] EP-X24 Item\n      Dept: rf-ui\n',
        },
        pathExists: exists,
      );
      expect(missing.length, 1);
      expect(missing.single.startsWith('MISSING_VERIFY:'), isTrue);
      expect(missing.any((String s) => s.startsWith('VERIFY_')), isFalse);
    });
  });

  group('EP-T24 RED→GREEN guard proof (temporary queue tree)', () {
    test(
        'valid target is clean; missing/placeholder/dangling fail closed; restore is clean',
        () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t24_queue_');
      // EP-T27: this fixture's item declares `rf-platform`, so its queue file
      // name must route to rf-platform (the name was arbitrary before routing
      // was checked); see the read() map below.
      final File queue = File(
        '${temp.path}${Platform.pathSeparator}queues${Platform.pathSeparator}'
        'platform.md',
      );
      const Set<String> existing = <String>{
        'test/tool',
        'test/tool/queue_item_schema_guard_test.dart',
        'lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md',
      };
      bool exists(String path) => existing.contains(path);
      // rf-platform owns the `lib/features/kvm/platform/**` doc-existence
      // target used by the EP-P1-shaped GREEN case below; test/tool targets
      // are dept-agnostic.
      String item(String verify) =>
          '- [ ] EP-X24 Item\n      Dept: rf-platform\n      Verify: $verify\n';
      try {
        queue.parent.createSync(recursive: true);
        Map<String, String> read() => <String, String>{
              'queues/platform.md': queue.readAsStringSync(),
            };

        // GREEN: a concrete repo-existing suite target.
        queue.writeAsStringSync(item(
            '`flutter test test/tool/queue_item_schema_guard_test.dart && flutter analyze` (0 issues);'));
        expect(evaluateQueueSchema(read(), pathExists: exists), isEmpty);

        // RED 1 (missing): a non-empty command that names no target path.
        queue.writeAsStringSync(item('`flutter analyze` (0 issues);'));
        expect(
          evaluateQueueSchema(read(), pathExists: exists)
              .any((String v) => v.startsWith('VERIFY_NO_TARGET:')),
          isTrue,
        );

        // RED 2 (placeholder / typo'd suite): a named path that does not exist.
        queue.writeAsStringSync(
            item('`flutter test test/tool/placeholder_typo_test.dart`'));
        expect(
          evaluateQueueSchema(read(), pathExists: exists)
              .any((String v) => v.startsWith('VERIFY_DANGLING_TARGET:')),
          isTrue,
        );

        // RED 3 (dangling lib doc-existence target).
        queue.writeAsStringSync(item(
            '`test -f lib/features/kvm/platform/MISSING_MATRIX.md && flutter analyze`'));
        expect(
          evaluateQueueSchema(read(), pathExists: exists)
              .any((String v) => v.startsWith('VERIFY_DANGLING_TARGET:')),
          isTrue,
        );

        // GREEN: glob target normalises to the existing test/tool base.
        queue.writeAsStringSync(
            item('`flutter test test/tool/** && flutter analyze`'));
        expect(evaluateQueueSchema(read(), pathExists: exists), isEmpty);

        // GREEN: the legitimate EP-P1 shape (lib doc existence) is accepted.
        queue.writeAsStringSync(item(
            '`test -f lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md && flutter analyze`'));
        expect(evaluateQueueSchema(read(), pathExists: exists), isEmpty);

        // GREEN: one valid target rescues a command that also lists a typo.
        queue.writeAsStringSync(item(
            '`flutter test test/tool/nope_test.dart test/tool/queue_item_schema_guard_test.dart`'));
        expect(evaluateQueueSchema(read(), pathExists: exists), isEmpty);

        // GREEN again once the canonical command is restored.
        queue.writeAsStringSync(item(
            '`flutter test test/tool/queue_item_schema_guard_test.dart && flutter analyze` (0 issues);'));
        expect(evaluateQueueSchema(read(), pathExists: exists), isEmpty);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('EP-T24 real repository verify-target invariant', () {
    test('every unchecked verify command names a repo-existing target', () {
      final Map<String, String> queues = readRealQueues();
      expect(queues.length, 5, reason: 'expected the five dept queue files');
      final List<QueueItem> all = <QueueItem>[];
      queues.forEach((String file, String raw) {
        all.addAll(parseUncheckedItems(file, stripHtmlComments(raw)));
      });
      int withTarget = 0;
      for (final QueueItem item in all) {
        if (extractVerifyTargets(item.verify.join(' ')).isNotEmpty) {
          withTarget++;
        }
      }
      expect(withTarget, greaterThanOrEqualTo(15),
          reason: 'target extractor saw too few commands');
      // The checked-in queues are clean against the real filesystem.
      expect(evaluateQueueSchema(queues), isEmpty);
      // Liveness: if every path vanished, the very same real queues must fail
      // closed on dangling targets — proving the invariant is not vacuous.
      final List<String> forced =
          evaluateQueueSchema(queues, pathExists: (_) => false);
      expect(
        forced.any((String v) => v.startsWith('VERIFY_DANGLING_TARGET:')),
        isTrue,
        reason: 'real-repo target invariant did not fail when paths vanished',
      );
    });
  });

  group('EP-T25 dept <-> product-path ownership evaluator (pure)', () {
    // A permissive path-existence predicate isolates the ownership check from
    // EP-T24's dangling-target check so each pure case names exactly one cause.
    bool exists(String _) => true;
    String item(String dept, String scope) => '- [ ] EP-X25 Item\n'
        '      Dept: $dept\n'
        '      Verify: `flutter test test/tool/ && flutter analyze` (0 issues);\n'
        '              writes limited to `$scope`.\n';
    // EP-T27: the temp file name must route to the dept under test so the
    // routing guard stays silent and each case names exactly one cause.
    List<String> check(String dept, String scope) => evaluateQueueSchema(
          <String, String>{
            'queues/${dept.replaceFirst('rf-', '')}.md': item(dept, scope)
          },
          pathExists: exists,
        );

    test('ownership map covers the nine depts; non-product depts own none', () {
      expect(deptOwnedProductPaths.keys.toSet(), allowedDepartments);
      for (final String dept in <String>[
        'rf-tooling',
        'rf-audit',
        'rf-ideate',
        'rf-check',
        'rf-gate',
      ]) {
        expect(deptOwnedProductPaths[dept], isEmpty, reason: dept);
      }
    });

    test('pathIsOwned matches the prefix itself and descendants on / only', () {
      const List<String> models = <String>['lib/features/kvm/models'];
      expect(pathIsOwned('lib/features/kvm/models', models), isTrue);
      expect(pathIsOwned('lib/features/kvm/models/foo.dart', models), isTrue);
      expect(pathIsOwned('lib/features/kvm/models_extra', models), isFalse);
      expect(pathIsOwned('lib/features/kvm', models), isFalse);
      expect(pathIsOwned('lib/features/kvm/models', const <String>[]), isFalse);
    });

    test('a dept naming an owned product path is clean', () {
      expect(check('rf-model', 'lib/features/kvm/models/**'), isEmpty);
      expect(check('rf-ui', 'lib/features/kvm/views/**'), isEmpty);
      expect(check('rf-service', 'lib/features/kvm/kvm_service.dart'), isEmpty);
      expect(check('rf-platform', 'lib/features/kvm/platform/**'), isEmpty);
    });

    test('a dept naming a foreign product path fails closed', () {
      final List<String> v = check('rf-ui', 'lib/features/kvm/models/**');
      expect(
        v.any((String s) =>
            s.startsWith('DEPT_PATH_OWNERSHIP:') &&
            s.contains('dept=rf-ui') &&
            s.contains('lib/features/kvm/models')),
        isTrue,
        reason: v.join(' | '),
      );
      // The diagnostic names the offending item's file and line.
      expect(v.single, contains('queues/ui.md:1'));
    });

    test('a no-product-lib dept naming any product path fails closed', () {
      for (final String dept in <String>[
        'rf-tooling',
        'rf-audit',
        'rf-ideate',
        'rf-check',
        'rf-gate',
      ]) {
        expect(
          check(dept, 'lib/features/kvm/models/**').any(
            (String s) => s.startsWith('DEPT_PATH_OWNERSHIP:'),
          ),
          isTrue,
          reason: dept,
        );
      }
    });

    test('shared test/tool paths stay exempt for every dept', () {
      for (final String dept in allowedDepartments) {
        expect(
          check(dept, 'test/features/kvm/**'),
          isEmpty,
          reason: dept,
        );
      }
    });

    test('every product path is checked; one foreign among owned fails', () {
      final List<String> v = evaluateQueueSchema(
        <String, String>{
          'queues/model.md': item(
            'rf-model',
            'lib/features/kvm/models/** + lib/features/kvm/views/**',
          ),
        },
        pathExists: exists,
      );
      expect(
        v.where((String s) => s.startsWith('DEPT_PATH_OWNERSHIP:')).length,
        1,
        reason: v.join(' | '),
      );
      expect(v.single, contains('lib/features/kvm/views'));
    });

    test('an invalid dept reports its schema violation, not ownership', () {
      final List<String> v = check('rf-evil', 'lib/features/kvm/models/**');
      expect(v.any((String s) => s.startsWith('BAD_DEPT:')), isTrue);
      expect(
          v.any((String s) => s.startsWith('DEPT_PATH_OWNERSHIP:')), isFalse);
    });
  });

  group('EP-T25 RED→GREEN guard proof (temporary queue tree)', () {
    test('owned path is clean; foreign / no-lib-dept paths fail; restore clean',
        () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t25_queue_');
      final File queue = File(
        '${temp.path}${Platform.pathSeparator}queues${Platform.pathSeparator}'
        'ui.md',
      );
      bool exists(String _) => true;
      String item(String dept, String scope) => '- [ ] EP-X25 Item\n'
          '      Dept: $dept\n'
          '      Verify: `flutter test test/tool/` writes limited to `$scope`.\n';
      Map<String, String> read() => <String, String>{
            'queues/ui.md': queue.readAsStringSync(),
          };
      try {
        queue.parent.createSync(recursive: true);

        // GREEN: a dept naming its own product path.
        queue.writeAsStringSync(item('rf-ui', 'lib/features/kvm/views/**'));
        expect(evaluateQueueSchema(read(), pathExists: exists), isEmpty);

        // RED 1: a dept naming another dept's product path.
        queue.writeAsStringSync(item('rf-ui', 'lib/features/kvm/models/**'));
        expect(
          evaluateQueueSchema(read(), pathExists: exists)
              .any((String s) => s.startsWith('DEPT_PATH_OWNERSHIP:')),
          isTrue,
        );

        // RED 2: a no-product-lib dept naming any product path.
        queue.writeAsStringSync(
            item('rf-tooling', 'lib/features/kvm/platform/**'));
        expect(
          evaluateQueueSchema(read(), pathExists: exists)
              .any((String s) => s.startsWith('DEPT_PATH_OWNERSHIP:')),
          isTrue,
        );

        // GREEN again once the owned path is restored.
        queue.writeAsStringSync(item('rf-ui', 'lib/features/kvm/views/**'));
        expect(evaluateQueueSchema(read(), pathExists: exists), isEmpty);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('EP-T25 real repository product-path ownership invariant', () {
    test('every unchecked item names only dept-owned product paths', () {
      final Map<String, String> queues = readRealQueues();
      expect(queues.length, 5, reason: 'expected the five dept queue files');
      final List<QueueItem> all = <QueueItem>[];
      queues.forEach((String file, String raw) {
        all.addAll(parseUncheckedItems(file, stripHtmlComments(raw)));
      });
      int productPaths = 0;
      for (final QueueItem item in all) {
        productPaths += extractVerifyTargets(item.verify.join(' '))
            .where((String p) => p.startsWith('lib/'))
            .length;
      }
      expect(productPaths, greaterThanOrEqualTo(10),
          reason: 'ownership guard saw too few product paths (vacuous?)');
      // The checked-in queues satisfy single-writer path ownership.
      expect(evaluateQueueSchema(queues), isEmpty);
      // Non-vacuity: with every dept's ownership removed, the very same real
      // queues fail closed on the product paths that were just accepted.
      final List<String> forced = evaluateQueueSchema(
        queues,
        ownedPaths: <String, List<String>>{},
      );
      expect(
        forced.any((String s) => s.startsWith('DEPT_PATH_OWNERSHIP:')),
        isTrue,
        reason: 'real-repo ownership invariant did not fail with no owners',
      );
    });
  });

  group('EP-T27 dept <-> queue-file routing evaluator (pure)', () {
    // Permissive predicates isolate the routing check from EP-T24's target
    // check and EP-T25's ownership check, so each case names exactly one cause.
    bool exists(String _) => true;
    String item(String dept) => '- [ ] EP-X27 Item\n'
        '      Dept: $dept\n'
        '      Verify: `flutter test test/tool/` (0 issues);\n';
    List<String> check(String file, String dept) => evaluateQueueSchema(
          <String, String>{file: item(dept)},
          pathExists: exists,
        );

    test('the routing map covers exactly the five dept queue files', () {
      expect(deptForQueueFile.length, 5);
      expect(deptForQueueFile, <String, String>{
        'queues/platform.md': 'rf-platform',
        'queues/model.md': 'rf-model',
        'queues/ui.md': 'rf-ui',
        'queues/service.md': 'rf-service',
        'queues/tooling.md': 'rf-tooling',
      });
      expect(deptForQueueFile['queues/unknown.md'], isNull);
    });

    test('an item whose dept matches its queue file is clean', () {
      deptForQueueFile.forEach((String file, String dept) {
        expect(check(file, dept), isEmpty, reason: '$file / $dept');
      });
    });

    test('a mis-filed dept fails closed with file, line and both depts', () {
      final List<String> v = check('queues/ui.md', 'rf-model');
      expect(
        v.any((String s) =>
            s.startsWith('DEPT_QUEUE_MISMATCH:') &&
            s.contains('file=queues/ui.md') &&
            s.contains('dept=rf-model') &&
            s.contains('expected rf-ui')),
        isTrue,
        reason: v.join(' | '),
      );
      expect(v.single, contains('queues/ui.md:1'));
    });

    test('every queue file rejects a dept belonging to another file', () {
      deptForQueueFile.forEach((String file, String dept) {
        final String foreign = dept == 'rf-ui' ? 'rf-model' : 'rf-ui';
        expect(
          check(file, foreign)
              .any((String s) => s.startsWith('DEPT_QUEUE_MISMATCH:')),
          isTrue,
          reason: '$file declaring $foreign',
        );
      });
    });

    test('missing / duplicate / invalid dept reports only its schema cause',
        () {
      for (final String bad in <String>[
        '- [ ] EP-X27 Item\n      Verify: `flutter test test/tool/`\n',
        '- [ ] EP-X27 Item\n      Dept: rf-ui\n      Dept: rf-model\n' +
            '      Verify: `flutter test test/tool/`\n',
        '- [ ] EP-X27 Item\n      Dept: rf-evil\n' +
            '      Verify: `flutter test test/tool/`\n',
      ]) {
        expect(
          evaluateQueueSchema(<String, String>{'queues/ui.md': bad},
                  pathExists: exists)
              .any((String s) => s.startsWith('DEPT_QUEUE_MISMATCH:')),
          isFalse,
          reason: bad,
        );
      }
    });

    test('an unknown queue file skips the routing check', () {
      expect(check('queues/unknown.md', 'rf-ui'), isEmpty);
    });
  });

  group('EP-T27 RED→GREEN guard proof (temporary queue tree)', () {
    test('matching dept is clean; mis-filed dept fails; restore is clean', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t27_queue_');
      final File queue = File(
        '${temp.path}${Platform.pathSeparator}queues${Platform.pathSeparator}'
        'ui.md',
      );
      bool exists(String _) => true;
      String item(String dept) => '- [ ] EP-X27 Item\n'
          '      Dept: $dept\n'
          '      Verify: `flutter test test/tool/` (0 issues);\n';
      Map<String, String> read() => <String, String>{
            'queues/ui.md': queue.readAsStringSync(),
          };
      try {
        queue.parent.createSync(recursive: true);

        // GREEN: the dept matches the file that carries the item.
        queue.writeAsStringSync(item('rf-ui'));
        expect(evaluateQueueSchema(read(), pathExists: exists), isEmpty);

        // RED: a model item filed in the UI queue fails closed.
        queue.writeAsStringSync(item('rf-model'));
        expect(
          evaluateQueueSchema(read(), pathExists: exists)
              .any((String s) => s.startsWith('DEPT_QUEUE_MISMATCH:')),
          isTrue,
        );

        // GREEN again once the correct dept is restored.
        queue.writeAsStringSync(item('rf-ui'));
        expect(evaluateQueueSchema(read(), pathExists: exists), isEmpty);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('EP-T27 real repository dept-routing invariant', () {
    test('every unchecked item is filed in its own dept queue file', () {
      final Map<String, String> queues = readRealQueues();
      expect(queues.length, 5, reason: 'expected the five dept queue files');
      final List<QueueItem> all = <QueueItem>[];
      queues.forEach((String file, String raw) {
        all.addAll(parseUncheckedItems(file, stripHtmlComments(raw)));
      });
      int routed = 0;
      for (final QueueItem item in all) {
        if (item.dept.length == 1 &&
            deptForQueueFile[item.file] == item.dept.single) {
          routed++;
        }
      }
      expect(routed, greaterThanOrEqualTo(15),
          reason: 'routing guard saw too few correctly-filed items (vacuous?)');
      // The checked-in queues are clean against the canonical file→dept map.
      expect(evaluateQueueSchema(queues), isEmpty);
      // Non-vacuity: with every file routed to a foreign dept, the very same
      // real queues fail closed on DEPT_QUEUE_MISMATCH (no real queue mutation).
      final List<String> forced = evaluateQueueSchema(
        queues,
        deptForFile: deptForQueueFile.map(
          (String file, String dept) => MapEntry<String, String>(
            file,
            dept == 'rf-ui' ? 'rf-model' : 'rf-ui',
          ),
        ),
      );
      expect(
        forced.any((String s) => s.startsWith('DEPT_QUEUE_MISMATCH:')),
        isTrue,
        reason: 'real-repo routing invariant did not fail on a foreign map',
      );
    });
  });
}
