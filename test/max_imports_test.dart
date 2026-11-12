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

  String _usedPrefixedCoreImports(int count) {
    final imports = List.generate(
      count,
      (i) => "import 'dart:core' as c$i;",
    ).join('\n');
    // Edge case: every import is used so the analyzer's unused_import never fires beside this rule
    final uses = List.generate(count, (i) => 'c$i.int? v$i;').join('\n');

    return '$imports\n$uses\n';
  }

  Future<void> test_overTheDefaultBudget() async {
    await assertDiagnostics(_usedPrefixedCoreImports(16), [lint(0, 25)]);
  }

  Future<void> test_atTheDefaultBudget() async {
    await assertNoDiagnostics(_usedPrefixedCoreImports(15));
  }

  Future<void> test_fewImports() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
import 'dart:math';

Future<int>? f;
final r = Random();
''');
  }

  Future<void> test_barrelExportsAreNotCountedByDefault() async {
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
