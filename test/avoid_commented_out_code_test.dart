import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_commented_out_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidCommentedOutCodeTest));
}

@reflectiveTest
class AvoidCommentedOutCodeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCommentedOutCode();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_singleLineCommentedOutCode() async {
    await assertDiagnostics(
      r'''
// final x = 42;
void f() {}
''',
      [lint(0, 16)],
    );
  }

  Future<void> test_multiLineCommentedOutCode() async {
    await assertDiagnostics(
      r'''
// void apply(String value) {
//   print(value);
// }
void f() {}
''',
      [lint(0, 53)],
    );
  }

  Future<void> test_commentedOutImport() async {
    await assertDiagnostics(
      r'''
// import 'dart:async';
void f() {}
''',
      [lint(0, 23)],
    );
  }

  Future<void> test_commentedOutMethodCall() async {
    await assertDiagnostics(
      r'''
// print('hello');
void f() {}
''',
      [lint(0, 18)],
    );
  }

  Future<void> test_commentedOutClassDeclaration() async {
    await assertDiagnostics(
      r'''
// class Foo {
//   void bar() {}
// }
void f() {}
''',
      [lint(0, 38)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_regularComment() async {
    await assertNoDiagnostics(r'''
// This is a regular descriptive comment
void f() {}
''');
  }

  Future<void> test_todoComment() async {
    await assertNoDiagnostics(r'''
void f() {}
''');
  }

  Future<void> test_docComment() async {
    await assertNoDiagnostics(r'''
/// This is a doc comment with code example:
/// ```dart
/// final x = 42;
/// ```
void f() {}
''');
  }

  Future<void> test_ignoreDirective() async {
    await assertNoDiagnostics(r'''
// ignore: unused_local_variable
void f() {
  final x = 42;
}
''');
  }

  Future<void> test_ignoreForFileDirective() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_local_variable
void f() {
  final x = 42;
}
''');
  }

  Future<void> test_descriptiveCommentWithMultipleWords() async {
    await assertNoDiagnostics(r'''
// This function handles the main application logic
// and processes all incoming requests appropriately
void f() {}
''');
  }

  // --- Edge cases ---

  Future<void> test_commentWithAnnotation() async {
    await assertDiagnostics(
      r'''
// @override
// void build() {}
void f() {}
''',
      [lint(0, 31)],
    );
  }

  Future<void> test_commentedOutAssignment() async {
    await assertDiagnostics(
      r'''
// x = 42;
void f() {}
''',
      [lint(0, 10)],
    );
  }
}
