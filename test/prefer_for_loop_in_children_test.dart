import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_for_loop_in_children.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferForLoopInChildrenTest),
  );
}

@reflectiveTest
class PreferForLoopInChildrenTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferForLoopInChildren();
    super.setUp();
  }

  // ===== Pattern 1: .map().toList() =====

  Future<void> test_mapToList_triggers() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  final result = list.map((e) => e.toString()).toList();
}
''',
      [lint(54, 38)],
    );
  }

  Future<void> test_mapToList_withBlockBody_triggers() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  final result = list.map((e) { return e.toString(); }).toList();
}
''',
      [lint(54, 47)],
    );
  }

  Future<void> test_mapOnly_noToList_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.map((e) => e.toString());
}
''');
  }

  Future<void> test_mapToSet_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.map((e) => e.toString()).toSet();
}
''');
  }

  // ===== Pattern 2: spread with .map() =====

  Future<void> test_spreadMap_triggers() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  final result = [...list.map((e) => e.toString())];
}
''',
      [lint(55, 32)],
    );
  }

  Future<void> test_spreadMapToList_triggers() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  final result = [...list.map((e) => e.toString()).toList()];
}
''',
      [lint(55, 41)],
    );
  }

  Future<void> test_spreadWithoutMap_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  final other = [4, 5];
  final result = [...list, ...other];
}
''');
  }

  // ===== Pattern 3: List.generate() =====

  Future<void> test_listGenerate_triggers() async {
    await assertDiagnostics(
      r'''
void f() {
  final result = List.generate(5, (index) => index * 2);
}
''',
      [lint(28, 38)],
    );
  }

  Future<void> test_listGenerateWithTypeArgs_triggers() async {
    await assertDiagnostics(
      r'''
void f() {
  final result = List<int>.generate(5, (index) => index * 2);
}
''',
      [lint(28, 43)],
    );
  }

  Future<void> test_listGenerateNoCallback_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
void f() {
  final result = List.filled(5, 0);
}
''');
  }

  // ===== Pattern 4: .fold() =====

  Future<void> test_foldWithEmptyList_triggers() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  final result = list.fold<List<String>>([], (acc, e) {
    acc.add(e.toString());
    return acc;
  });
}
''',
      [lint(54, 86)],
    );
  }

  Future<void> test_foldWithNonEmptyInitial_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.fold<int>(0, (acc, e) => acc + e);
}
''');
  }

  Future<void> test_foldWithoutCallback_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.fold<int>(0, add);
}
int add(int a, int b) => a + b;
''');
  }

  // ===== Edge cases =====

  Future<void> test_forLoop_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  final result = [for (final e in list) e.toString()];
}
''');
  }

  Future<void> test_mapWithNamedFunction_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
String convert(int i) => i.toString();
void f() {
  final list = [1, 2, 3];
  final result = list.map(convert).toList();
}
''');
  }
}
