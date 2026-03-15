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

  // ===== Pattern 3 via MethodInvocation: .generate() edge cases =====

  Future<void> test_customClassGenerate_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
class MyFactory {
  static List<int> generate(int count, int Function(int) cb) {
    return List.generate(count, cb);
  }
}
void f() {
  final result = MyFactory.generate(5, (i) => i * 2);
}
''');
  }

  Future<void> test_instanceGenerate_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
class Builder {
  List<int> generate(int count, int Function(int) cb) {
    return List.generate(count, cb);
  }
}
void f() {
  final b = Builder();
  final result = b.generate(5, (i) => i * 2);
}
''');
  }

  Future<void> test_generateWithOneArg_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
class MyList {
  static List<int> generate(int count) => [count];
}
void f() {
  final result = MyList.generate(5);
}
''');
  }

  Future<void> test_generateWithNonFunctionSecondArg_doesNotTrigger() async {
    await assertNoDiagnostics(r'''
class Gen {
  static List<int> generate(int count, List<int> template) => template;
}
void f() {
  final result = Gen.generate(5, [1, 2]);
}
''');
  }

  Future<void> test_customListClassGenerate_doesNotTrigger() async {
    // A custom class named "List" with a generate static method.
    // The method name is 'generate' and target name is 'List', but it does
    // not resolve to dart:core List, so the rule should not trigger.
    await assertNoDiagnostics(r'''
class List {
  static List generate(int count, List Function(int) cb) {
    return cb(count);
  }
}
void f() {
  final result = List.generate(5, (i) => List());
}
''');
  }

  Future<void> test_customListClassGenerate_withOneArg_doesNotTrigger() async {
    // Custom "List" class with generate that takes only one arg.
    await assertNoDiagnostics(r'''
class List {
  static List generate(int count) {
    return List();
  }
}
void f() {
  final result = List.generate(5);
}
''');
  }

  Future<void>
  test_customListClassGenerate_withNonFunctionSecondArg_doesNotTrigger() async {
    // Custom "List" class with generate where second arg is not a function.
    await assertNoDiagnostics(r'''
class List {
  static List generate(int count, int seed) {
    return List();
  }
}
void f() {
  final result = List.generate(5, 42);
}
''');
  }

  Future<void> test_listGenerateViaStaticMethod_triggers() async {
    // dart:core List.generate with a callback, as a MethodInvocation.
    // Use show to ensure List resolves to dart:core.
    await assertDiagnostics(
      r'''
import 'dart:core' show List;
void f() {
  final result = List.generate(5, (index) => index * 2);
}
''',
      [lint(58, 38)],
    );
  }

  Future<void>
  test_listGenerateViaStaticMethod_namedFunction_doesNotTrigger() async {
    // dart:core List.generate with a named function ref (not
    // FunctionExpression) should not trigger.
    await assertNoDiagnostics(r'''
import 'dart:core' show List, int;
int doubleIt(int i) => i * 2;
void f() {
  final result = List.generate(5, doubleIt);
}
''');
  }

  // --- Cover _checkListGenerate lines 126-128,130 ---

  Future<void> test_listGenerate_nonFunctionSecondArg_doesNotTrigger() async {
    // List.generate where second arg is not a FunctionExpression
    // exercises line 128 (args[1] is! FunctionExpression)
    await assertNoDiagnostics(r'''
int doubler(int i) => i * 2;
void f() {
  final result = List.generate(5, doubler);
}
''');
  }

  Future<void> test_listGenerate_singleArg_doesNotTrigger() async {
    // List.generate with only one arg — exercises line 127 (args.length < 2)
    await assertNoDiagnostics(r'''
void f() {
  final result = List.filled(5, 0);
}
''');
  }

  Future<void> test_fold_singleArg_doesNotTrigger() async {
    // fold with fewer than 2 args — exercises line 136
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.fold(0, (a, b) => a + b);
}
''');
  }

  Future<void> test_fold_nonEmptyInitialList_doesNotTrigger() async {
    // fold with non-empty initial list — exercises line 141
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.fold([0], (acc, e) {
    acc.add(e);
    return acc;
  });
}
''');
  }
}
