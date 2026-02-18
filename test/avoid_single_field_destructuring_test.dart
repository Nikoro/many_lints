import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_single_field_destructuring.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidSingleFieldDestructuringTest),
  );
}

@reflectiveTest
class AvoidSingleFieldDestructuringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidSingleFieldDestructuring();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_objectPattern_singleField_triggers() async {
    await assertDiagnostics(
      r'''
class Foo {
  final int value;
  Foo(this.value);
}

void f(Foo input) {
  final Foo(:value) = input;
}
''',
      [lint(75, 25)],
    );
  }

  Future<void> test_objectPattern_singleNamedField_triggers() async {
    await assertDiagnostics(
      r'''
class Foo {
  final int value;
  Foo(this.value);
}

void f(Foo input) {
  final Foo(value: v) = input;
}
''',
      [lint(75, 27)],
    );
  }

  Future<void> test_recordPattern_singleField_triggers() async {
    await assertDiagnostics(
      r'''
void f(({int length}) record) {
  final (:length) = record;
}
''',
      [lint(34, 24)],
    );
  }

  Future<void> test_varKeyword_triggers() async {
    await assertDiagnostics(
      r'''
class Foo {
  final int value;
  Foo(this.value);
}

void f(Foo input) {
  var Foo(:value) = input;
}
''',
      [lint(75, 23)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_objectPattern_multipleFields_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  final int x;
  final int y;
  Foo(this.x, this.y);
}

void f(Foo input) {
  final Foo(:x, :y) = input;
}
''');
  }

  Future<void> test_recordPattern_multipleFields_noLint() async {
    await assertNoDiagnostics(r'''
void f((int, String) record) {
  final (a, b) = record;
}
''');
  }

  Future<void> test_directPropertyAccess_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  final int value;
  Foo(this.value);
}

void f(Foo input) {
  final value = input.value;
}
''');
  }
}
