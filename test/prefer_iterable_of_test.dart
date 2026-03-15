import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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

  Future<void> test_methodInvocation_notFrom_noLint() async {
    // Method invocation but not 'from' — should not trigger
    await assertNoDiagnostics(r'''
void f() {
  final intList = [1, 2, 3];
  final copy = List.of(intList);
}
''');
  }

  Future<void> test_methodInvocation_nonListSetTarget_noLint() async {
    // Method invocation 'from' but not on List/Set
    await assertNoDiagnostics(r'''
class MyClass {
  static List<int> from(List<int> source) => source;
}

void f() {
  final intList = [1, 2, 3];
  final copy = MyClass.from(intList);
}
''');
  }

  Future<void> test_setFromWithoutExplicitTypeArg_methodInvocation() async {
    // Set.from() via method invocation with compatible types
    await assertDiagnostics(
      r'''
void f() {
  final strings = <String>{'a', 'b'};
  final copy = Set.from(strings);
}
''',
      [lint(64, 17)],
    );
  }

  Future<void> test_listFrom_customIterableSubtype() async {
    // Source is a custom Iterable subtype — exercises _getIterableElementType
    // supertype fallback
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

  // --- Cover visitMethodInvocation _check call (line 75) with Set.from ---

  Future<void> test_setFromWithoutTypeArgs_methodInvocation() async {
    // Set.from() without type args — parsed as MethodInvocation
    await assertDiagnostics(
      r'''
void f() {
  final intList = [1, 2, 3];
  final copy = Set.from(intList);
}
''',
      [lint(55, 17)],
    );
  }

  // --- Cover _getIterableElementType supertype fallback (lines 127-130) ---

  Future<void> test_listFrom_customIterable_supertypeFallback() async {
    // Custom Iterable subclass where typeArguments may not be on the class
    // itself but on the Iterable supertype
    await assertDiagnostics(
      r'''
class MyInts extends Iterable<int> {
  @override
  Iterator<int> get iterator => <int>[].iterator;
}

void f() {
  final source = MyInts();
  final copy = List<int>.from(source);
}
''',
      [
        error(diag.nonAbstractClassInheritsAbstractMemberFivePlus, 6, 6),
        lint(155, 22),
      ],
    );
  }

  // --- Cover non-InterfaceType source (line 107 early return) ---

  Future<void> test_listFrom_dynamicSource_noLint() async {
    // Source has non-InterfaceType (dynamic) — exercises line 107 early return
    await assertNoDiagnostics(r'''
void f(dynamic source) {
  final copy = List<int>.from(source);
}
''');
  }

  // --- Cover multiple positional args (line 87 early return) ---

  Future<void> test_listFrom_withGrowableArg() async {
    // List.from with growable named arg — should still trigger
    await assertDiagnostics(
      r'''
void f() {
  final intList = [1, 2, 3];
  final copy = List<int>.from(intList, growable: false);
}
''',
      [lint(55, 40)],
    );
  }
}
