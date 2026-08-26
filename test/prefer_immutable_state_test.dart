import 'package:many_lints/src/rules/prefer_immutable_state.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferImmutableStateTest));
}

@reflectiveTest
class PreferImmutableStateTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferImmutableState();
    // Faithful to the real `package:meta`: `hasImmutable` resolves through the
    // library *name* and the `Immutable` class, so a lowercase stand-in would
    // never be recognised as the annotation it imitates.
    newPackage('meta').addFile('lib/meta.dart', r'''
library meta;

class Immutable {
  const Immutable([this.reason]);
  final String? reason;
}
const Immutable immutable = Immutable();
''');
    newPackage('flutter').addFile('lib/widgets.dart', r'''
import 'package:meta/meta.dart';

@immutable
abstract class Widget {}
abstract class StatelessWidget extends Widget {
  Widget build(Object context);
}
abstract class StatefulWidget extends Widget {
  State createState();
}
abstract class State<T extends StatefulWidget> {
  void setState(void Function() fn) {}
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_stateClassWithoutImmutable() async {
    await assertDiagnostics(
      r'''
class MyFeatureState {}
''',
      [lint(6, 14)],
    );
  }

  Future<void> test_noBlocDependencyRequired() async {
    // The whole point of this rule: it covers Riverpod notifier state and any
    // other `...State` class, in a project with no `bloc` anywhere.
    await assertDiagnostics(
      r'''
class LoginEmailState {
  LoginEmailState(this.email);
  final String email;
}
''',
      [lint(6, 15)],
    );
  }

  Future<void> test_subclassesAreWidenedIn() async {
    await assertDiagnostics(
      r'''
sealed class CounterState {}
class CounterInitial extends CounterState {}
''',
      [lint(13, 12), lint(35, 14)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_annotatedStateClass() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class MyFeatureState {}
''');
  }

  Future<void> test_classNotNamedState() async {
    await assertNoDiagnostics(r'''
class MyFeature {}
''');
  }

  Future<void> test_classNamedExactlyState() async {
    // The bare affix is not a state class, it is the whole word.
    await assertNoDiagnostics(r'''
class State {}
''');
  }

  // ---- Edge cases ----

  Future<void> test_flutterStateSubclassIsMeantToBeMutable() async {
    // Every Flutter `State<T>` is named `...State` and every one of them holds
    // mutable fields by design. Reporting these would flag every
    // StatefulWidget in a codebase.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class LoginPage extends StatefulWidget {
  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int counter = 0;
}
''');
  }

  Future<void> test_widgetNamedStateInheritsImmutable() async {
    // `EmptyState`, `ErrorState`, `LoadingState` are ordinary widget names.
    // `StatelessWidget` inherits `@immutable` from `Widget`, so the annotation
    // the rule asks for is already there.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class PersonPickerEmptyState extends StatelessWidget {
  @override
  Widget build(Object context) => this;
}
''');
  }

  Future<void> test_classInheritingImmutableFromItsOwnBase() async {
    // Not a Flutter concern: any base annotated `@immutable` passes the
    // annotation down, so the subclass has nothing left to add.
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class Snapshot {}

class LoginState extends Snapshot {}
''');
  }

  Future<void> test_mutableStateClassStillReported() async {
    // The fix must not weaken the rule for the classes it exists for.
    await assertDiagnostics(
      r'''
class CounterState {
  int count = 0;
}
''',
      [lint(6, 12)],
    );
  }

  Future<void> test_partiallyAnnotatedHierarchy() async {
    await assertDiagnostics(
      r'''
import 'package:meta/meta.dart';

@immutable
sealed class CounterState {}
class CounterInitial extends CounterState {}
''',
      [lint(80, 14)],
    );
  }
}
