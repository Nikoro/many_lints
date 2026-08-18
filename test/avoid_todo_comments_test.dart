// ignore_for_file: implementation_imports
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:many_lints/src/rules/avoid_todo_comments.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidTodoCommentsTest));
}

@reflectiveTest
class AvoidTodoCommentsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidTodoComments();
    super.setUp();
  }

  Future<void> test_bare_todo() async {
    await assertDiagnostics(
      r'''
void upload() {
  // TODO: handle the 409 conflict case
}
''',
      [lint(18, 37), error(diag.todo, 21, 34)],
    );
  }

  Future<void> test_bare_fixme() async {
    await assertDiagnostics(
      r'''
void upload() {
  // FIXME: this retries forever
}
''',
      [lint(18, 30), error(diag.fixme, 21, 27)],
    );
  }

  Future<void> test_hack_in_a_doc_comment() async {
    await assertDiagnostics(
      r'''
/// HACK: works around the broken header
void upload() {}
''',
      [lint(0, 40), error(diag.hack, 4, 36)],
    );
  }

  Future<void> test_flutter_style_todo_without_an_issue() async {
    await assertDiagnostics(
      r'''
void upload() {
  // TODO(dominik): handle the 409 conflict case
}
''',
      [lint(18, 46), error(diag.todo, 21, 43)],
    );
  }

  Future<void> test_todo_referencing_an_issue_number() async {
    await assertDiagnostics(
      r'''
void upload() {
  // TODO(#42): handle the 409 conflict case
}
''',
      [error(diag.todo, 21, 39)],
    );
  }

  Future<void> test_todo_referencing_a_url() async {
    await assertDiagnostics(
      r'''
void upload() {
  // TODO: handle this, https://github.com/example/repo/issues/42
}
''',
      [error(diag.todo, 21, 60)],
    );
  }

  Future<void> test_todo_referencing_a_tracker_key() async {
    await assertDiagnostics(
      r'''
void upload() {
  // TODO(PROJ-118): handle the 409 conflict case
}
''',
      [error(diag.todo, 21, 44)],
    );
  }

  Future<void> test_prose_mentioning_a_marker_is_not_a_marker() async {
    await assertDiagnostics(
      r'''
void upload() {
  // The TODO above explains why this is ordered as it is.
}
''',
      [error(diag.todo, 25, 49)],
    );
  }

  Future<void> test_a_word_starting_with_a_marker_is_not_a_marker() async {
    await assertNoDiagnostics(r'''
void upload() {
  // TODOS.md lists the remaining work.
  // HACKATHON notes live in the wiki.
}
''');
  }

  Future<void> test_an_ordinary_comment() async {
    await assertNoDiagnostics(r'''
void upload() {
  // Retries are handled by the caller.
}
''');
  }
}
