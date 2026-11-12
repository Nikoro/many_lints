import 'package:many_lints/src/rules/prefer_declaring_const_constructor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferDeclaringConstConstructorTest),
  );
}

@reflectiveTest
class PreferDeclaringConstConstructorTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferDeclaringConstConstructor();
    super.setUp();
  }

  Future<void> test_finalFieldsWithNonConstConstructor() async {
    await assertDiagnostics(
      r'''
class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}
''',
      [lint(47, 22)],
    );
  }

  Future<void> test_alreadyConst() async {
    await assertNoDiagnostics(r'''
class Point {
  final int x;

  const Point(this.x);
}
''');
  }

  Future<void> test_mutableFieldCannotBeConst() async {
    await assertNoDiagnostics(r'''
class Point {
  int x;

  Point(this.x);
}
''');
  }

  Future<void> test_constructorWithABody() async {
    await assertNoDiagnostics(r'''
class Point {
  final int x;

  Point(this.x) {
    print(x);
  }
}
''');
  }

  Future<void> test_immutableAnnotatedClassIsLeftToTheSdkLint() async {
    await assertNoDiagnostics(r'''
class Immutable {
  const Immutable();
}

const immutable = Immutable();

@immutable
class Point {
  final int x;

  Point(this.x);
}
''');
  }

  Future<void> test_initializerWithACallIsNotConstEvaluable() async {
    await assertNoDiagnostics(r'''
class Generator {
  final Object _source;

  Generator([Object? source]) : _source = source ?? Object();
}
''');
  }

  Future<void> test_parameterInitializerIsConstEvaluable() async {
    await assertDiagnostics(
      r'''
class Point {
  final int x;

  Point(int value) : x = value;
}
''',
      [lint(32, 29)],
    );
  }

  Future<void> test_severalConstructorsIsAJudgementCall() async {
    await assertNoDiagnostics(r'''
class Point {
  final int x;

  Point(this.x);
  Point.origin() : x = 0;
}
''');
  }
}
