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

  Future<void> test_constructorWithoutParameters() async {
    await assertDiagnostics(
      r'''
class Calculator {
  const Calculator();

  int twice(int x) => x * 2;
}
''',
      [lint(6, 10)],
    );
  }

  Future<void> test_classWithMethod() async {
    await assertDiagnostics(
      r'''
class WithMethod {
  final int v;
  WithMethod(this.v);
  int get doubled => v * 2;
}
''',
      [lint(6, 10)],
    );
  }

  Future<void> test_initializerList() async {
    await assertDiagnostics(
      r'''
class Guarded {
  final int x;
  Guarded(this.x) : assert(x > 0);
}
''',
      [lint(6, 7)],
    );
  }

  Future<void> test_constructorBody() async {
    await assertDiagnostics(
      r'''
class Logging {
  final int x;
  Logging(this.x) {
    print(x);
  }
}
''',
      [lint(6, 7)],
    );
  }

  Future<void> test_mutableField() async {
    await assertDiagnostics(
      r'''
class Counter {
  int count;
  Counter(this.count);
}
''',
      [lint(6, 7)],
    );
  }

  Future<void> test_plainParameterAssignedInInitializerList() async {
    await assertDiagnostics(
      r'''
class Indirect {
  final int x;
  Indirect(int value) : x = value;
}
''',
      [lint(6, 8)],
    );
  }

  Future<void> test_fieldsTheConstructorDoesNotDeclareStay() async {
    await assertDiagnostics(
      r'''
class Defaulted {
  final int x;
  final int y = 0;
  static const int max = 10;
  Defaulted(this.x);
}
''',
      [lint(6, 9)],
    );
  }

  Future<void> test_superParameters() async {
    await assertDiagnostics(
      r'''
class Base {
  final int id;
  const Base(this.id);
}

class Derived extends Base {
  final int x;
  const Derived(super.id, this.x);
}
''',
      [lint(6, 4), lint(61, 7)],
    );
  }

  Future<void> test_abstractClass() async {
    await assertDiagnostics(
      r'''
abstract class Shape {
  final int sides;
  const Shape(this.sides);
  double get area;
}
''',
      [lint(15, 5)],
    );
  }

  Future<void> test_namedConstructor() async {
    await assertDiagnostics(
      r'''
class Named {
  final int x;
  Named._(this.x);
  factory Named.parse(String s) => Named._(int.parse(s));
}
''',
      [lint(6, 5)],
    );
  }

  Future<void> test_redirectingConstructorBeside() async {
    await assertDiagnostics(
      r'''
class Pair {
  final int x;
  Pair(this.x);
  Pair.zero() : this(0);
}
''',
      [lint(6, 4)],
    );
  }

  Future<void> test_enumConstructor() async {
    await assertDiagnostics(
      r'''
enum Color {
  red('#f00'),
  green('#0f0');

  const Color(this.hex);

  final String hex;
}
''',
      [lint(5, 5)],
    );
  }

  Future<void> test_genericClass() async {
    await assertDiagnostics(
      r'''
class Box<T> {
  final T value;
  const Box(this.value);
}
''',
      [lint(6, 3)],
    );
  }

  Future<void> test_trivialMixinClassConstructor() async {
    await assertDiagnostics(
      r'''
mixin class Mixable {
  Mixable();
}
''',
      [lint(12, 7)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_typeWithoutConstructorIsNotReported() async {
    await assertNoDiagnostics(r'''
class Empty {
  final int x = 1;
  int get y => x;
}
''');
  }

  Future<void> test_enumWithoutConstructorIsNotReported() async {
    await assertNoDiagnostics(r'''
enum Sport { squash, padel }
''');
  }

  Future<void> test_interfaceWithoutConstructorIsNotReported() async {
    await assertNoDiagnostics(r'''
abstract interface class Gateway {
  Future<void> send();
}
''');
  }

  Future<void> test_twoGenerativeConstructorsAreNotReported() async {
    await assertNoDiagnostics(r'''
class Pair {
  final int x;
  Pair(this.x);
  Pair.zero() : x = 0;
}
''');
  }

  Future<void> test_onlyFactoryConstructorsAreNotReported() async {
    await assertNoDiagnostics(r'''
class Parsed {
  factory Parsed(String s) => _Impl();
}

class _Impl implements Parsed {}
''');
  }

  Future<void> test_lateFieldAssignedByConstructorIsNotReported() async {
    await assertNoDiagnostics(r'''
class Late {
  late final int x;
  Late(this.x);
}
''');
  }

  Future<void> test_explicitlyTypedThisParameterIsNotReported() async {
    await assertNoDiagnostics(r'''
class Narrow {
  final num x;
  Narrow(int this.x);
}
''');
  }

  Future<void> test_functionTypedThisParameterIsNotReported() async {
    await assertNoDiagnostics(r'''
class Callback {
  final void Function(int) cb;
  Callback(this.cb(int value));
}
''');
  }

  Future<void> test_partiallyDeclaredMultiFieldIsNotReported() async {
    await assertNoDiagnostics(r'''
class Split {
  final int a, b;
  Split(this.a) : b = 0;
}
''');
  }

  Future<void> test_annotatedConstructorIsNotReported() async {
    await assertNoDiagnostics(r'''
class Old {
  final int x;
  @Deprecated('use New')
  Old(this.x);
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
