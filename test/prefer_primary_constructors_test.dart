import 'package:many_lints/src/rules/prefer_primary_constructors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferPrimaryConstructorsTest),
  );
}

@reflectiveTest
class PreferPrimaryConstructorsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferPrimaryConstructors();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_simpleFieldAssigningConstructor() async {
    await assertDiagnostics(
      r'''
class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}
''',
      [lint(6, 5)],
    );
  }

  Future<void> test_singleField() async {
    await assertDiagnostics(
      r'''
class Wrapper {
  final int value;
  Wrapper(this.value);
}
''',
      [lint(6, 7)],
    );
  }

  Future<void> test_namedParameters() async {
    await assertDiagnostics(
      r'''
class Config {
  final int retries;
  Config({required this.retries});
}
''',
      [lint(6, 6)],
    );
  }

  Future<void> test_constConstructor() async {
    await assertDiagnostics(
      r'''
class Point {
  final int x;
  const Point(this.x);
}
''',
      [lint(6, 5)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_classWithMethodIsNotReported() async {
    await assertNoDiagnostics(r'''
class WithMethod {
  final int v;
  WithMethod(this.v);
  int get doubled => v * 2;
}
''');
  }

  Future<void> test_constructorWithInitializerListIsNotReported() async {
    await assertNoDiagnostics(r'''
class Guarded {
  final int x;
  Guarded(this.x) : assert(x > 0);
}
''');
  }

  Future<void> test_constructorWithBodyIsNotReported() async {
    await assertNoDiagnostics(r'''
class Logging {
  final int x;
  Logging(this.x) {
    print(x);
  }
}
''');
  }

  Future<void> test_mutableFieldIsNotReported() async {
    await assertNoDiagnostics(r'''
class Counter {
  int count;
  Counter(this.count);
}
''');
  }

  Future<void> test_plainParameterIsNotReported() async {
    await assertNoDiagnostics(r'''
class Indirect {
  final int x;
  Indirect(int value) : x = value;
}
''');
  }

  Future<void> test_initializedFieldIsNotReported() async {
    await assertNoDiagnostics(r'''
class Defaulted {
  final int x;
  final int y = 0;
  Defaulted(this.x);
}
''');
  }

  Future<void> test_staticFieldIsNotReported() async {
    await assertNoDiagnostics(r'''
class WithStatic {
  static const int max = 10;
  final int x;
  WithStatic(this.x);
}
''');
  }

  Future<void> test_subclassIsNotReported() async {
    await assertNoDiagnostics(r'''
class Base {
  const Base();
}

class Derived extends Base {
  final int x;
  Derived(this.x);
}
''');
  }

  Future<void> test_abstractClassIsNotReported() async {
    await assertNoDiagnostics(r'''
abstract class Shape {
  final int sides;
  Shape(this.sides);
}
''');
  }

  Future<void> test_twoConstructorsIsNotReported() async {
    await assertNoDiagnostics(r'''
class Pair {
  final int x;
  Pair(this.x);
  Pair.zero() : x = 0;
}
''');
  }

  Future<void> test_namedConstructorIsNotReported() async {
    await assertNoDiagnostics(r'''
class Named {
  final int x;
  Named.of(this.x);
}
''');
  }

  /// A field the constructor does not assign has to be initialized some other
  /// way, so the class is not a pure field-list-plus-constructor shape.
  Future<void> test_uncoveredFieldIsNotReported() async {
    await assertNoDiagnostics(r'''
class Partial {
  final int x;
  final int y;
  Partial(this.x) : y = 0;
}
''');
  }

  /// Isolates the "every field must be covered" branch: `y` is late, so the
  /// class compiles without the constructor assigning it, and the rule must
  /// still decline because `y` has no place in the primary constructor.
  Future<void> test_lateFieldNotAssignedByConstructorIsNotReported() async {
    await assertNoDiagnostics(r'''
class Partial {
  final int x;
  late final int y;
  Partial(this.x);
}
''');
  }

  Future<void> test_classWithNoConstructorIsNotReported() async {
    await assertNoDiagnostics(r'''
class Empty {
  final int x = 1;
}
''');
  }

  Future<void> test_alreadyPrimaryConstructorIsNotReported() async {
    await assertNoDiagnostics(r'''
class Point(final int x, final int y);
''');
  }

  // --- Edge case: the language-feature gate ---

  Future<void> test_notReportedBeforeDart313() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class Point {
  final int x;
  Point(this.x);
}
''');
  }
}
