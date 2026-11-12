import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_commented_out_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidCommentedOutCodeTest));
}

@reflectiveTest
class AvoidCommentedOutCodeTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidCommentedOutCode();
    super.setUp();
  }

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

  Future<void> test_commentedOutReturnStatement() async {
    await assertDiagnostics(
      r'''
// return value
void f() {}
''',
      [lint(0, 15)],
    );
  }

  Future<void> test_commentedOutCascade() async {
    await assertDiagnostics(
      r'''
// ..add(item);
void f() {}
''',
      [lint(0, 15)],
    );
  }

  Future<void> test_commentedOutAssignmentWithoutSemicolon() async {
    await assertDiagnostics(
      r'''
// value += something
void f() {}
''',
      [lint(0, 21)],
    );
  }

  Future<void> test_commentWithoutSpaceAfterSlashes() async {
    await assertDiagnostics(
      r'''
//final x = 42;
void f() {}
''',
      [lint(0, 15)],
    );
  }

  Future<void> test_commentAtEndOfFile() async {
    await assertDiagnostics(
      r'''
void f() {}
// final x = 42;
''',
      [lint(12, 16)],
    );
  }

  Future<void> test_separatedCommentGroups() async {
    await assertDiagnostics(
      r'''
// final x = 42;

// final y = 99;
void f() {}
''',
      [lint(0, 16), lint(18, 16)],
    );
  }

  Future<void> test_proseInLaterClassDoesNotSuppress() async {
    await assertDiagnostics(
      r'''
class BadExamples {
  // void apply(String value) {
  //   print(value);
  // }

  void another() {}
}

class GoodExamples {
  // This method handles the main processing logic
  // and delegates to the appropriate handler

  void another() {}
}
''',
      [lint(22, 57)],
    );
  }

  Future<void> test_trailingCommentNotGroupedWithNextLine() async {
    await assertDiagnostics(
      r'''
void f() {} // final x = 42;
// final y = 99;
void g() {}
''',
      [lint(12, 16), lint(29, 16)],
    );
  }

  Future<void> test_nonConsecutiveCommentGroups() async {
    await assertDiagnostics(
      r'''
// final x = 42;
void a() {}
void b() {}
void c() {}
void d() {}
void e() {}
void ff() {}
void gg() {}
void hh() {}
void ii() {}
void jj() {}
void kk() {}
void ll() {}
// final y = 99;
void z() {}
''',
      [lint(0, 16), lint(168, 16)],
    );
  }

  Future<void> test_commentedOutAnnotationOnly() async {
    await assertDiagnostics(
      r'''
// @override
void f() {}
''',
      [lint(0, 12)],
    );
  }

  Future<void> test_commentedOutCascadeOnly() async {
    await assertDiagnostics(
      r'''
// ..removeAll(items);
void f() {}
''',
      [lint(0, 22)],
    );
  }

  Future<void> test_proseStartingWithBareOverrideIsNotCode() async {
    await assertNoDiagnostics(r'''
// override this method in subclasses to customize the behaviour
void f() {}
''');
  }

  Future<void> test_commentedOutCodeAfterEofToken() async {
    await assertDiagnostics(
      r'''
void f() {}
// final z = 100;
''',
      [lint(12, 17)],
    );
  }
}
