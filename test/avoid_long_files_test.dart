import 'package:many_lints/src/rules/avoid_long_files.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidLongFilesTest));
}

@reflectiveTest
class AvoidLongFilesTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidLongFiles();
    super.setUp();
  }

  /// A file of [count] trivial declarations, one per line.
  String _fileOf(int count) =>
      List.generate(count, (i) => 'const x$i = $i;').join('\n');

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_fileOverTheDefaultBudget() async {
    await assertDiagnostics(_fileOf(301), [lint(0, 0)]);
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_fileAtTheDefaultBudget() async {
    await assertNoDiagnostics(_fileOf(300));
  }

  Future<void> test_shortFile() async {
    await assertNoDiagnostics(_fileOf(10));
  }

  // ---- Edge cases ----

  Future<void> test_commentsAndBlankLinesDoNotCount() async {
    // 300 lines of code plus 100 lines of comment and blank stays inside the
    // budget, because a well-documented file is not a hard-to-navigate one.
    final padding = List.generate(50, (_) => '// a comment\n').join();
    await assertNoDiagnostics('$padding${_fileOf(300)}\n$padding');
  }

  Future<void> test_emptyFile() async {
    await assertNoDiagnostics('');
  }
}
