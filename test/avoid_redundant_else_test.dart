import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_redundant_else.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidRedundantElseTest));
}

@reflectiveTest
class AvoidRedundantElseTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRedundantElse();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_elseAfterReturn() async {
    await assertDiagnostics(
      r'''
int classify(bool flag) {
  if (flag) {
    return 1;
  } else {
    return 2;
  }
}
''',
      [lint(58, 4)],
    );
  }

  Future<void> test_elseAfterThrow() async {
    await assertDiagnostics(
      r'''
int classify(bool flag) {
  if (flag) {
    throw 'bad';
  } else {
    return 2;
  }
}
''',
      [lint(61, 4)],
    );
  }

  Future<void> test_elseAfterReturnWithoutBraces() async {
    await assertDiagnostics(
      r'''
int classify(bool flag) {
  if (flag) return 1;
  else return 2;
}
''',
      [lint(50, 4)],
    );
  }

  Future<void> test_elseAfterContinueInLoop() async {
    await assertDiagnostics(
      r'''
void run(List<int> items) {
  for (final item in items) {
    if (item.isEven) {
      continue;
    } else {
      print(item);
    }
  }
}
''',
      [lint(103, 4)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_thenDoesNotExit() async {
    await assertNoDiagnostics(r'''
void classify(bool flag) {
  if (flag) {
    print('yes');
  } else {
    print('no');
  }
}
''');
  }

  Future<void> test_noElse() async {
    await assertNoDiagnostics(r'''
int classify(bool flag) {
  if (flag) {
    return 1;
  }
  return 2;
}
''');
  }

  Future<void> test_elseIfChain() async {
    await assertNoDiagnostics(r'''
int classify(int value) {
  if (value < 0) {
    return -1;
  } else if (value > 0) {
    return 1;
  }
  return 0;
}
''');
  }

  Future<void> test_returnNotLastStatement() async {
    await assertNoDiagnostics(r'''
int classify(bool flag) {
  if (flag) {
    if (flag) return 1;
    print('fallthrough');
  } else {
    return 2;
  }
  return 3;
}
''');
  }

  Future<void> test_emptyThenBlock() async {
    await assertNoDiagnostics(r'''
void classify(bool flag) {
  if (flag) {
  } else {
    print('no');
  }
}
''');
  }

  Future<void> test_throwInsideNestedIfOnly() async {
    await assertNoDiagnostics(r'''
void classify(bool a, bool b) {
  if (a) {
    if (b) throw 'bad';
  } else {
    print('no');
  }
}
''');
  }
}
