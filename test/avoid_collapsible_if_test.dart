import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_collapsible_if.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidCollapsibleIfTest));
}

@reflectiveTest
class AvoidCollapsibleIfTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidCollapsibleIf();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_nestedIfInBlocks() async {
    await assertDiagnostics(
      r'''
void check(bool a, bool b) {
  if (a) {
    if (b) {
      print('both');
    }
  }
}
''',
      [lint(31, 2)],
    );
  }

  Future<void> test_nestedIfWithoutBraces() async {
    await assertDiagnostics(
      r'''
void check(bool a, bool b) {
  if (a) if (b) print('both');
}
''',
      [lint(31, 2)],
    );
  }

  Future<void> test_nestedIfWithMultipleInnerStatements() async {
    await assertDiagnostics(
      r'''
void check(bool a, bool b) {
  if (a) {
    if (b) {
      print('one');
      print('two');
    }
  }
}
''',
      [lint(31, 2)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_outerHasElse() async {
    await assertNoDiagnostics(r'''
void check(bool a, bool b) {
  if (a) {
    if (b) {
      print('both');
    }
  } else {
    print('neither');
  }
}
''');
  }

  Future<void> test_innerHasElse() async {
    await assertNoDiagnostics(r'''
void check(bool a, bool b) {
  if (a) {
    if (b) {
      print('both');
    } else {
      print('only a');
    }
  }
}
''');
  }

  Future<void> test_statementBeforeInnerIf() async {
    await assertNoDiagnostics(r'''
void check(bool a, bool b) {
  if (a) {
    print('a');
    if (b) {
      print('both');
    }
  }
}
''');
  }

  Future<void> test_statementAfterInnerIf() async {
    await assertNoDiagnostics(r'''
void check(bool a, bool b) {
  if (a) {
    if (b) {
      print('both');
    }
    print('a');
  }
}
''');
  }

  Future<void> test_singleIf() async {
    await assertNoDiagnostics(r'''
void check(bool a) {
  if (a) {
    print('a');
  }
}
''');
  }

  Future<void> test_outerCaseClause() async {
    await assertNoDiagnostics(r'''
void check(Object value, bool b) {
  if (value case int _) {
    if (b) {
      print('both');
    }
  }
}
''');
  }

  Future<void> test_innerCaseClause() async {
    await assertNoDiagnostics(r'''
void check(bool a, Object value) {
  if (a) {
    if (value case int _) {
      print('both');
    }
  }
}
''');
  }

  Future<void> test_elseIfChainIsNotCollapsible() async {
    await assertNoDiagnostics(r'''
void check(bool a, bool b) {
  if (a) {
    print('a');
  } else if (b) {
    print('b');
  }
}
''');
  }
}
