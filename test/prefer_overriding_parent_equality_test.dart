import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/prefer_overriding_parent_equality.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferOverridingParentEqualityTest),
  );
}

@reflectiveTest
class PreferOverridingParentEqualityTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferOverridingParentEquality();
    // `Mock` overrides `==`/`hashCode` for identity, which is what `verify()`
    // matches on. `Fake` overrides nothing — a Fake subclass reaches this rule
    // through the interface it implements.
    newPackage('mocktail').addFile('lib/src/mocktail.dart', r'''
class Mock {
  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) => identical(this, other);
}
''');
    newPackage('test_api').addFile('lib/src/frontend/fake.dart', r'''
abstract class Fake {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw '';
}
''');
    // `Widget` overrides `==` and `hashCode` so that identity is runtimeType
    // plus key — exactly the shape this rule reports on, and exactly the one
    // no widget should override.
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Key {}

abstract class Widget {
  const Widget({this.key});

  final Key? key;

  @override
  bool operator ==(Object other) => super == other;

  @override
  int get hashCode => super.hashCode;
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(Object context);
}
''');
    super.setUp();
  }

  /// Overrides the base config so the rule sees a different `ignored_types`.
  void _configureIgnoredTypes(String body) {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  prefer_overriding_parent_equality:
$body
''');
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_childMissingBothEqualsAndHashCode() async {
    await assertDiagnostics(
      r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);
}
''',
      [lint(134, 5)],
    );
  }

  Future<void> test_childMissingOnlyEquals() async {
    await assertDiagnostics(
      r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);

  @override
  int get hashCode => value.hashCode;
}
''',
      [lint(134, 5)],
    );
  }

  Future<void> test_childMissingOnlyHashCode() async {
    await assertDiagnostics(
      r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);

  @override
  bool operator ==(Object other) =>
      other is Child && value == other.value;
}
''',
      [lint(134, 5)],
    );
  }

  Future<void> test_grandparentOverridesEquality() async {
    await assertDiagnostics(
      r'''
class GrandParent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Parent extends GrandParent {}

class Child extends Parent {
  final int x;
  Child(this.x);
}
''',
      [lint(139, 6), lint(176, 5)],
    );
  }

  Future<void> test_childWithNoFields() async {
    await assertDiagnostics(
      r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {}
''',
      [lint(134, 5)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_childOverridesBoth() async {
    await assertNoDiagnostics(r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Child && value == other.value;
}
''');
  }

  Future<void> test_parentDoesNotOverrideEquality() async {
    await assertNoDiagnostics(r'''
class Parent {
  final int x;
  Parent(this.x);
}

class Child extends Parent {
  final String y;
  Child(this.y) : super(0);
}
''');
  }

  Future<void> test_parentOnlyOverridesEquals() async {
    await assertNoDiagnostics(r'''
class Parent {
  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);
}
''');
  }

  Future<void> test_parentOnlyOverridesHashCode() async {
    await assertNoDiagnostics(r'''
class Parent {
  @override
  int get hashCode => 42;
}

class Child extends Parent {
  final String value;
  Child(this.value);
}
''');
  }

  Future<void> test_abstractChildIsSkipped() async {
    await assertNoDiagnostics(r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

abstract class Child extends Parent {
  final String value;
  Child(this.value);
}
''');
  }

  Future<void> test_noSuperclass() async {
    await assertNoDiagnostics(r'''
class Standalone {
  final int x;
  Standalone(this.x);
}
''');
  }

  // --- ignored_types ---

  Future<void> test_widgetSubclassIsIgnoredByDefault() async {
    // A widget's identity is its runtimeType and key; comparing fields
    // instead would break the framework's element reuse.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Greeting extends StatelessWidget {
  const Greeting(this.name);

  final String name;

  @override
  Widget build(Object context) => this;
}
''');
  }

  Future<void> test_indirectWidgetSubclassIsIgnoredByDefault() async {
    // Matching is by supertype, so a project's own widget base is covered
    // without naming it.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class BrandedWidget extends StatelessWidget {
  const BrandedWidget();
}

class Greeting extends BrandedWidget {
  const Greeting(this.name);

  final String name;

  @override
  Widget build(Object context) => this;
}
''');
  }

  Future<void> test_ignoredTypesCanBeReplaced() async {
    // Replacing the set drops `Widget` from it, so widgets report again.
    _configureIgnoredTypes('    ignored_types:\n      - Marker');
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class Greeting extends StatelessWidget {
  const Greeting(this.name);

  final String name;

  @override
  Widget build(Object context) => this;
}
''',
      [lint(46, 8)],
    );
  }

  Future<void> test_additionalIgnoredTypesExtendsTheDefault() async {
    _configureIgnoredTypes('    additional_ignored_types:\n      - Parent');
    await assertNoDiagnostics(r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);
}
''');
  }

  Future<void> test_nonWidgetStillReportedWithTheDefaultSet() async {
    // The default exclusion must not weaken the rule for ordinary classes.
    await assertDiagnostics(
      r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);
}
''',
      [lint(134, 5)],
    );
  }

  // --- Mock and Fake defaults ---

  Future<void> test_mockSubclassIsIgnoredByDefault() async {
    // A mock's identity is the instance, which is what `verify()` matches on.
    await assertNoDiagnostics(r'''
import 'package:mocktail/src/mocktail.dart';

class Repository {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class MockRepository extends Mock implements Repository {}
''');
  }

  Future<void> test_fakeSubclassIsIgnoredByDefault() async {
    // `Fake` itself overrides nothing: the subclass inherits `==` from the
    // interface it implements, with no fields of its own to compare.
    await assertNoDiagnostics(r'''
import 'package:test_api/src/frontend/fake.dart';

class Person {
  Person(this.name);

  final String name;

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) => other is Person && name == other.name;
}

class FakePerson extends Fake implements Person {}
''');
  }

  Future<void> test_aProjectClassNamedMockDoesNotSwitchTheRuleOff() async {
    // The pin is what keeps a domain class from silently exempting its whole
    // subtree. `Mock` and `Fake` are ordinary English words.
    await assertDiagnostics(
      r'''
class Mock {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Mock {
  Child(this.value);
  final String value;
}
''',
      [lint(132, 5)],
    );
  }
}
