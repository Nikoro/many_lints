import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_equatable_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferEquatableMixinTest));
}

@reflectiveTest
class PreferEquatableMixinTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferEquatableMixin();
    newPackage('equatable').addFile('lib/equatable.dart', r'''
abstract class Equatable {
  const Equatable();
  List<Object?> get props;
}

mixin EquatableMixin {
  List<Object?> get props;
}
''');
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_extendsEquatable() async {
    await assertDiagnostics(
      r'''
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}
''',
      [lint(57, 17)],
    );
  }

  Future<void> test_extendsEquatableWithConst() async {
    await assertDiagnostics(
      r'''
import 'package:equatable/equatable.dart';

class Point extends Equatable {
  const Point(this.x, this.y);
  final double x;
  final double y;

  @override
  List<Object?> get props => [x, y];
}
''',
      [lint(56, 17)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_usesEquatableMixin() async {
    await assertNoDiagnostics(r'''
import 'package:equatable/equatable.dart';

class Person with EquatableMixin {
  Person(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}
''');
  }

  Future<void> test_notEquatable() async {
    await assertNoDiagnostics(r'''
class Person {
  const Person(this.name);
  final String name;
}
''');
  }

  Future<void> test_extendsOtherClass() async {
    await assertNoDiagnostics(r'''
class Base {}

class Child extends Base {
  Child(this.name);
  final String name;
}
''');
  }

  // --- Edge cases ---

  Future<void> test_abstractClassExtendsEquatable() async {
    await assertDiagnostics(
      r'''
import 'package:equatable/equatable.dart';

abstract class BaseEntity extends Equatable {
  const BaseEntity();
}
''',
      [lint(70, 17)],
    );
  }
}
