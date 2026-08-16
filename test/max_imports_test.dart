import 'package:many_lints/src/rules/max_imports.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(MaxImportsTest));
}

@reflectiveTest
class MaxImportsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = MaxImports();
    super.setUp();
  }

  /// [count] prefixed imports of `dart:core`, each one used, so the
  /// analyzer's own `unused_import` cannot fire and only this rule is
  /// asserted.
  String _importsOf(int count) {
    final imports = List.generate(
      count,
      (i) => "import 'dart:core' as c$i;",
    ).join('\n');
    final uses = List.generate(count, (i) => 'c$i.int? v$i;').join('\n');

    return '$imports\n$uses\n';
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_overTheDefaultBudget() async {
    await assertDiagnostics(_importsOf(16), [lint(0, 25)]);
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_atTheDefaultBudget() async {
    await assertNoDiagnostics(_importsOf(15));
  }

  Future<void> test_fewImports() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
import 'dart:math';

Future<int>? f;
final r = Random();
''');
  }

  // ---- Edge cases ----

  Future<void> test_exportsAreNotCountedByDefault() async {
    // A barrel is exports by definition, so counting them would report every
    // barrel in a project.
    await assertNoDiagnostics(r'''
export 'dart:core';
export 'dart:async';
export 'dart:math';
export 'dart:collection';
export 'dart:convert';
export 'dart:typed_data';
''');
  }

  Future<void> test_noDirectivesAtAll() async {
    await assertNoDiagnostics(r'''
const x = 1;
''');
  }
}
