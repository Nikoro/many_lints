import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/prefer_moving_to_variable.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferMovingToVariableTest),
  );
}

@reflectiveTest
class PreferMovingToVariableTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferMovingToVariable();
    super.setUp();
  }

  // --- Cases that SHOULD trigger ---

  Future<void> test_repeatedInvocationChain_lint() async {
    await assertDiagnostics(
      r'''
class Theme {
  static Theme of(Object context) => Theme();
  int get primary => 0;
  int get secondary => 1;
}

void fn(Object context) {
  print(Theme.of(context).primary);
  print(Theme.of(context).secondary);
}
''',
      [lint(147, 17)],
    );
  }

  Future<void> test_repeatedPropertyChain_lint() async {
    await assertDiagnostics(
      r'''
class Inner {
  int get value => 0;
}

class Outer {
  Inner get inner => Inner();
}

void fn(Outer outer) {
  print(outer.inner.value);
  print(outer.inner.value);
}
''',
      [lint(117, 17)],
    );
  }

  // --- Cases that should NOT trigger ---

  /// A single link reads no worse than a variable would.
  Future<void> test_shortChain_noLint() async {
    await assertNoDiagnostics(r'''
class Holder {
  int get value => 0;
}

void fn(Holder holder) {
  print(holder.value);
  print(holder.value);
}
''');
  }

  Future<void> test_singleOccurrence_noLint() async {
    await assertNoDiagnostics(r'''
class Theme {
  static Theme of(Object context) => Theme();
  int get primary => 0;
}

void fn(Object context) {
  print(Theme.of(context).primary);
}
''');
  }

  /// A constructor allocates a fresh instance each time, so reusing one
  /// variable is observably different.
  Future<void> test_instanceCreation_noLint() async {
    await assertNoDiagnostics(r'''
class Thing {
  int get value => 0;
}

void fn() {
  print(Thing().value);
  print(Thing().value);
}
''');
  }

  /// A closure may run a different number of times, so the chain cannot be
  /// hoisted out of it.
  Future<void> test_insideClosure_noLint() async {
    await assertNoDiagnostics(r'''
class Theme {
  static Theme of(Object context) => Theme();
  int get primary => 0;
}

void fn(Object context, List<int> items) {
  items.map((e) => Theme.of(context).primary).toList();
}
''');
  }

  Future<void> test_assignmentTarget_noLint() async {
    await assertNoDiagnostics(r'''
class Inner {
  int value = 0;
}

class Outer {
  Inner get inner => Inner();
}

void fn(Outer outer) {
  outer.inner.value = 1;
  outer.inner.value = 2;
}
''');
  }
}
