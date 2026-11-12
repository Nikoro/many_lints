import 'package:many_lints/src/rules/avoid_nested_shorthands.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidNestedShorthandsTest));
}

@reflectiveTest
class AvoidNestedShorthandsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedShorthands();
    super.setUp();
  }

  static const _declarations = r'''
class SomeClass {
  final Label value;
  const SomeClass(this.value);
  static const SomeClass empty = SomeClass(Label.blank);
}

class Label {
  final String text;
  const Label(this.text);
  static const Label blank = Label('');
}

class Some {
  final SomeClass version;
  const Some({required this.version});
}

class Another {
  final Some some;
  Another(this.some);
  factory Another.of(Some some) => Another(some);
  static Another make(Some some) => Another(some);
}
''';

  Future<void> test_nestedConstructorInConstructor() async {
    await assertDiagnostics(
      '''
$_declarations
void fn() {
  final Another a = .new(.new(version: .new(.blank)));
  print(a);
}
''',
      [lint(514, 27), lint(528, 12), lint(533, 6)],
    );
  }

  Future<void> test_nestedInsideExplicitOuterConstructor() async {
    await assertDiagnostics(
      '''
$_declarations
void fn() {
  final a = Another(.new(version: .new(.blank)));
  print(a);
}
''',
      [lint(523, 12), lint(528, 6)],
    );
  }

  Future<void> test_nestedPropertyAccess() async {
    await assertDiagnostics(
      '''
$_declarations
void fn() {
  final Some s = .new(version: .empty);
  print(s);
}
''',
      [lint(520, 6)],
    );
  }

  Future<void> test_nestedInsideStaticMethodShorthand() async {
    await assertDiagnostics(
      '''
$_declarations
void fn() {
  final Another a = .make(.new(version: .empty));
  print(a);
}
''',
      [lint(515, 21), lint(529, 6)],
    );
  }

  Future<void> test_nestedInsideFactoryShorthand() async {
    await assertDiagnostics(
      '''
$_declarations
void fn() {
  final Another a = .of(.new(version: .empty));
  print(a);
}
''',
      [lint(513, 21), lint(527, 6)],
    );
  }

  Future<void> test_nestedBuriedInSubExpression() async {
    await assertDiagnostics(
      '''
$_declarations
void fn() {
  final Some s = .new(version: SomeClass(.blank));
  print(s);
}
''',
      [lint(530, 6)],
    );
  }

  Future<void> test_noLint_outerShorthandWithExplicitArguments() async {
    await assertNoDiagnostics('''
$_declarations
void fn() {
  final Another a = .new(Some(version: SomeClass(Label.blank)));
  print(a);
}
''');
  }

  Future<void> test_noLint_siblingShorthandsNotNested() async {
    await assertNoDiagnostics('''
$_declarations
void fn() {
  final SomeClass a = .empty;
  final Some b = .new(version: SomeClass(Label.blank));
  print('\$a \$b');
}
''');
  }

  Future<void> test_noLint_shorthandInPlainConstructorArgument() async {
    await assertNoDiagnostics('''
$_declarations
void fn() {
  final s = Some(version: .empty);
  print(s);
}
''');
  }

  Future<void> test_noLint_noShorthandsAtAll() async {
    await assertNoDiagnostics('''
$_declarations
void fn() {
  final a = Another(Some(version: SomeClass(Label.blank)));
  print(a);
}
''');
  }
}
