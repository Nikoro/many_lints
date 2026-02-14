import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_accessing_collections_by_constant_index.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidAccessingCollectionsByConstantIndexTest),
  );
}

@reflectiveTest
class AvoidAccessingCollectionsByConstantIndexTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAccessingCollectionsByConstantIndex();
    super.setUp();
  }

  // ── Positive cases (should trigger lint) ──

  Future<void> test_integerLiteralInForIn() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  for (final e in list) {
    list[0];
  }
}
''',
      [lint(67, 7)],
    );
  }

  Future<void> test_integerLiteralInForLoop() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  for (var i = 0; i < list.length; i++) {
    list[0];
  }
}
''',
      [lint(83, 7)],
    );
  }

  Future<void> test_integerLiteralInWhileLoop() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  var i = 0;
  while (i < list.length) {
    list[0];
    i++;
  }
}
''',
      [lint(82, 7)],
    );
  }

  Future<void> test_integerLiteralInDoWhileLoop() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  var i = 0;
  do {
    list[0];
    i++;
  } while (i < list.length);
}
''',
      [lint(61, 7)],
    );
  }

  Future<void> test_constVariableInLoop() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  const idx = 0;
  for (final e in list) {
    list[idx];
  }
}
''',
      [lint(84, 9)],
    );
  }

  Future<void> test_multipleConstantAccesses() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  for (final e in list) {
    list[0];
    list[1];
  }
}
''',
      [lint(67, 7), lint(80, 7)],
    );
  }

  // ── Negative cases (should NOT trigger lint) ──

  Future<void> test_outsideLoop() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  list[0];
}
''');
  }

  Future<void> test_loopVariableIndex() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  for (var i = 0; i < list.length; i++) {
    list[i];
  }
}
''');
  }

  Future<void> test_mutableVariableIndex() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  var idx = 0;
  for (final e in list) {
    list[idx];
    idx++;
  }
}
''');
  }

  Future<void> test_expressionIndex() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  for (var i = 0; i < list.length; i++) {
    list[i + 1];
  }
}
''');
  }

  Future<void> test_insideNestedClosure() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  for (final e in list) {
    () {
      list[0];
    };
  }
}
''');
  }

  Future<void> test_methodCallIndex() async {
    await assertNoDiagnostics(r'''
int getIndex() => 0;

void f() {
  final list = [1, 2, 3];
  for (final e in list) {
    list[getIndex()];
  }
}
''');
  }
}
