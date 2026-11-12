import 'package:many_lints/src/rules/max_statements.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(MaxStatementsTest));
}

@reflectiveTest
class MaxStatementsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = MaxStatements();
    super.setUp();
  }

  String _functionOf(int count) {
    final body = List.generate(count, (i) => '  var x$i = $i;').join('\n');
    return 'void f() {\n$body\n}\n';
  }

  Future<void> test_overTheDefaultBudget() async {
    await assertDiagnostics(_functionOf(26), [lint(5, 1)]);
  }

  Future<void> test_atTheDefaultBudget() async {
    await assertNoDiagnostics(_functionOf(25));
  }

  Future<void> test_shortFunction() async {
    await assertNoDiagnostics(r'''
void f() {
  print(1);
}
''');
  }

  Future<void> test_expressionBodyHasNoStatements() async {
    await assertNoDiagnostics(r'''
int f() => 1;
''');
  }

  Future<void> test_nestedCallbackIsCountedSeparatelyNotSummed() async {
    final outer = List.generate(20, (i) => '    var x$i = $i;').join('\n');
    final inner = List.generate(20, (i) => '    var y$i = $i;').join('\n');

    await assertNoDiagnostics('''
void f(List<int> xs) {
$outer
  xs.forEach((e) {
$inner
  });
}
''');
  }

  Future<void> test_statementsInsideLoopsCountTowardTheFunction() async {
    final body = List.generate(30, (i) => '    var x$i = $i;').join('\n');

    await assertDiagnostics(
      '''
void f(List<int> xs) {
  for (final x in xs) {
$body
  }
}
''',
      [lint(5, 1)],
    );
  }
}
