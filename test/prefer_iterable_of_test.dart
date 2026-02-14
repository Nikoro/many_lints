import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_iterable_of.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferIterableOfTest));
}

@reflectiveTest
class PreferIterableOfTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferIterableOf();
    super.setUp();
  }

  // --- Cases that SHOULD trigger the lint ---

  Future<void> test_listFromWithSameType() async {
    await assertDiagnostics(
      r'''
void f() {
  final intList = [1, 2, 3];
  final copy = List<int>.from(intList);
}
''',
      [lint(55, 23)],
    );
  }

  Future<void> test_setFromWithSameType() async {
    await assertDiagnostics(
      r'''
void f() {
  final intSet = <int>{1, 2, 3};
  final copy = Set<int>.from(intSet);
}
''',
      [lint(59, 21)],
    );
  }

  Future<void> test_listFromWithWiderType() async {
    await assertDiagnostics(
      r'''
void f() {
  final intList = [1, 2, 3];
  final numList = List<num>.from(intList);
}
''',
      [lint(58, 23)],
    );
  }

  Future<void> test_listFromWithoutExplicitTypeArg() async {
    await assertDiagnostics(
      r'''
void f() {
  final intList = [1, 2, 3];
  final copy = List.from(intList);
}
''',
      [lint(55, 18)],
    );
  }

  Future<void> test_setFromWithoutExplicitTypeArg() async {
    await assertDiagnostics(
      r'''
void f() {
  final intSet = <int>{1, 2, 3};
  final copy = Set.from(intSet);
}
''',
      [lint(59, 16)],
    );
  }

  // --- Cases that should NOT trigger the lint ---

  Future<void> test_listOfIsValid() async {
    await assertNoDiagnostics(r'''
void f() {
  final intList = [1, 2, 3];
  final copy = List<int>.of(intList);
}
''');
  }

  Future<void> test_setOfIsValid() async {
    await assertNoDiagnostics(r'''
void f() {
  final intSet = <int>{1, 2, 3};
  final copy = Set<int>.of(intSet);
}
''');
  }

  Future<void> test_listFromWithNarrowingType() async {
    // List<int>.from(numList) is a downcast — .from() is needed
    await assertNoDiagnostics(r'''
void f() {
  final numList = <num>[1, 2, 3];
  final intList = List<int>.from(numList);
}
''');
  }

  Future<void> test_setFromWithNarrowingType() async {
    // Set<int>.from(numSet) is a downcast — .from() is needed
    await assertNoDiagnostics(r'''
void f() {
  final numSet = <num>{1, 2, 3};
  final intSet = Set<int>.from(numSet);
}
''');
  }

  Future<void> test_listLiteralNotFlagged() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
}
''');
  }

  // --- Edge cases ---

  Future<void> test_listFromWithDynamicTarget() async {
    // List.from(dynamicList) where target is dynamic — still prefer .of()
    await assertDiagnostics(
      r'''
void f() {
  final list = <dynamic>[1, 'two', 3.0];
  final copy = List.from(list);
}
''',
      [lint(67, 15)],
    );
  }
}
