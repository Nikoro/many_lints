import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/prefer_iterable_of.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferIterableOfTest));
}

@reflectiveTest
class PreferIterableOfTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferIterableOf();
    super.setUp();
  }

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
    await assertNoDiagnostics(r'''
void f() {
  final numList = <num>[1, 2, 3];
  final intList = List<int>.from(numList);
}
''');
  }

  Future<void> test_setFromWithNarrowingType() async {
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

  Future<void> test_listFromWithDynamicTarget() async {
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
    await assertNoDiagnostics(r'''
void f() {
  final intList = [1, 2, 3];
  final copy = List.of(intList);
}
''');
  }

  Future<void> test_methodInvocation_nonListSetTarget_noLint() async {
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

  Future<void> test_setFromWithoutTypeArgs_methodInvocation() async {
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

  Future<void> test_listFrom_customIterable_supertypeFallback() async {
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

  Future<void> test_listFrom_dynamicSource_noLint() async {
    await assertNoDiagnostics(r'''
void f(dynamic source) {
  final copy = List<int>.from(source);
}
''');
  }

  Future<void> test_listFrom_withGrowableArg() async {
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
