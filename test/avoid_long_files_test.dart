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

  String _fileOf(int count) =>
      List.generate(count, (i) => 'const x$i = $i;').join('\n');

  Future<void> test_fileOverTheDefaultBudget() async {
    await assertDiagnostics(_fileOf(301), [lint(0, 0)]);
  }

  Future<void> test_fileAtTheDefaultBudget() async {
    await assertNoDiagnostics(_fileOf(300));
  }

  Future<void> test_shortFile() async {
    await assertNoDiagnostics(_fileOf(10));
  }

  Future<void> test_commentsAndBlankLinesDoNotCount() async {
    final padding = List.generate(50, (_) => '// a comment\n').join();
    await assertNoDiagnostics('$padding${_fileOf(300)}\n$padding');
  }

  Future<void> test_emptyFile() async {
    await assertNoDiagnostics('');
  }
}
