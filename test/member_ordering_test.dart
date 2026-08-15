import 'package:many_lints/src/rules/member_ordering.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(MemberOrderingTest));
}

@reflectiveTest
class MemberOrderingTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = MemberOrdering();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
abstract class Widget {}
abstract class StatelessWidget extends Widget {
  Widget build(Object context);
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_fieldAfterMethod() async {
    await assertDiagnostics(
      r'''
class A {
  void doWork() {}
  int count = 0;
}
''',
      [lint(31, 14)],
    );
  }

  Future<void> test_constructorAfterFieldIsFine() async {
    // The default puts the constructor first, matching modern Dart and
    // Flutter code — so a field below it is correct, not a violation.
    await assertNoDiagnostics(r'''
class A {
  A(this.count);

  final int count;
}
''');
  }

  Future<void> test_constructorAfterMethod() async {
    await assertDiagnostics(
      r'''
class A {
  void doWork() {}
  A();
}
''',
      [lint(31, 4)],
    );
  }

  Future<void> test_publicFieldAfterPrivateField() async {
    await assertDiagnostics(
      r'''
class A {
  int _internal = 0;
  int count = 0;
}
''',
      [lint(33, 14)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_correctOrder() async {
    await assertNoDiagnostics(r'''
class A {
  static const label = 'a';

  A();

  int count = 0;
  int _internal = 0;

  int get doubled => count * 2;

  void doWork() {}

  void _helper() {}
}
''');
  }

  Future<void> test_emptyClass() async {
    await assertNoDiagnostics(r'''
class A {}
''');
  }

  Future<void> test_singleMember() async {
    await assertNoDiagnostics(r'''
class A {
  void doWork() {}
}
''');
  }

  Future<void> test_buildMethodLast() async {
    await assertNoDiagnostics(r'''
class A {
  int count = 0;

  void helper() {}

  Object build() => count;
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_oneMisplacedMemberDoesNotSilenceTheRest() async {
    // The high-water mark is deliberately not lowered by a violation, so the
    // second field is still reported against the method above it.
    await assertDiagnostics(
      r'''
class A {
  void doWork() {}
  int first = 0;
  int second = 0;
}
''',
      [lint(31, 14), lint(48, 15)],
    );
  }

  Future<void> test_notifierBuildIsNotAWidgetBuild() async {
    // A Riverpod `Notifier.build` is the state initialiser and idiomatically
    // comes first; only a widget's `build` renders and belongs last. Without
    // the distinction, every helper below a notifier's build is reported.
    await assertNoDiagnostics(r'''
class AuthNotifier {
  Object? build() => null;

  void signOut() {}

  void _reset() {}
}
''');
  }

  Future<void> test_widgetBuildStillBelongsLast() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(Object context) => this;

  void helper() {}
}
''',
      [lint(136, 16)],
    );
  }

  Future<void> test_mixinIsOrderedToo() async {
    await assertDiagnostics(
      r'''
mixin M {
  void doWork() {}
  int count = 0;
}
''',
      [lint(31, 14)],
    );
  }

  Future<void> test_extensionIsOrderedToo() async {
    await assertDiagnostics(
      r'''
extension E on int {
  void doWork() {}
  static int count = 0;
}
''',
      [lint(42, 21)],
    );
  }
}
