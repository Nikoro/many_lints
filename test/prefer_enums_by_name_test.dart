import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_enums_by_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferEnumsByNameTest));
}

@reflectiveTest
class PreferEnumsByNameTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferEnumsByName();
    super.setUp();
  }

  Future<void> test_firstWhere_name_equals_string() async {
    await assertDiagnostics(
      r'''
enum Color { red, green, blue }

void f() {
  Color.values.firstWhere((e) => e.name == 'red');
}
''',
      [lint(46, 47)],
    );
  }

  Future<void> test_firstWhere_reversed_comparison() async {
    await assertDiagnostics(
      r'''
enum Color { red, green, blue }

void f() {
  Color.values.firstWhere((e) => 'red' == e.name);
}
''',
      [lint(46, 47)],
    );
  }

  Future<void> test_firstWhere_name_equals_variable() async {
    await assertDiagnostics(
      r'''
enum Color { red, green, blue }

void f(String name) {
  Color.values.firstWhere((e) => e.name == name);
}
''',
      [lint(57, 46)],
    );
  }

  Future<void> test_firstWhere_with_orElse() async {
    await assertDiagnostics(
      r'''
enum Color { red, green, blue }

void f() {
  Color.values.firstWhere((e) => e.name == 'red', orElse: () => Color.red);
}
''',
      [lint(46, 72)],
    );
  }

  Future<void> test_firstWhere_with_block_body() async {
    await assertDiagnostics(
      r'''
enum Color { red, green, blue }

void f() {
  Color.values.firstWhere((e) { return e.name == 'red'; });
}
''',
      [lint(46, 56)],
    );
  }

  // Negative cases

  Future<void> test_not_on_enum_values() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = <String>['a', 'b'];
  list.firstWhere((e) => e == 'a');
}
''');
  }

  Future<void> test_comparing_index_not_name() async {
    await assertNoDiagnostics(r'''
enum Color { red, green, blue }

void f() {
  Color.values.firstWhere((e) => e.index == 0);
}
''');
  }

  Future<void> test_where_not_firstWhere() async {
    await assertNoDiagnostics(r'''
enum Color { red, green, blue }

void f() {
  Color.values.where((e) => e.name == 'red');
}
''');
  }

  Future<void> test_not_equality_operator() async {
    await assertNoDiagnostics(r'''
enum Color { red, green, blue }

void f() {
  Color.values.firstWhere((e) => e.name != 'red');
}
''');
  }

  Future<void> test_complex_callback_body() async {
    await assertNoDiagnostics(r'''
enum Color { red, green, blue }

void f() {
  Color.values.firstWhere((e) => e.name == 'red' || e.name == 'blue');
}
''');
  }
}
