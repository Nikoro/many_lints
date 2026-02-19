import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_public_notifier_properties.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidPublicNotifierPropertiesTest),
  );
}

@reflectiveTest
class AvoidPublicNotifierPropertiesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidPublicNotifierProperties();

    final riverpod = newPackage('riverpod');
    riverpod.addFile('lib/riverpod.dart', r'''
abstract class Notifier<State> {
  State get state => throw UnimplementedError();
  set state(State value) {}
  State build();
}

abstract class AsyncNotifier<State> {
  State get state => throw UnimplementedError();
  set state(State value) {}
  Future<State> build();
}
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_publicGetter() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  int get publicGetter => 0;

  @override
  int build() => 0;
}
''',
      [lint(93, 12)],
    );
  }

  Future<void> test_publicSetter() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  set publicSetter(int value) {}

  @override
  int build() => 0;
}
''',
      [lint(89, 12)],
    );
  }

  Future<void> test_publicField() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  int publicField = 0;

  @override
  int build() => 0;
}
''',
      [lint(89, 11)],
    );
  }

  Future<void> test_publicFinalField() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  final int publicFinal = 0;

  @override
  int build() => 0;
}
''',
      [lint(95, 11)],
    );
  }

  Future<void> test_asyncNotifierPublicGetter() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends AsyncNotifier<int> {
  int get publicGetter => 0;

  @override
  Future<int> build() async => 0;
}
''',
      [lint(98, 12)],
    );
  }

  Future<void> test_multiplePublicFields() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  int fieldA = 0;
  int fieldB = 1;

  @override
  int build() => 0;
}
''',
      [lint(89, 6), lint(107, 6)],
    );
  }

  // --- Negative cases: should NOT trigger lint ---

  Future<void> test_privateGetter() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  int get _privateGetter => 0;

  @override
  int build() => 0;
}
''');
  }

  Future<void> test_privateSetter() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  int _value = 0;
  set _privateSetter(int value) => _value = value;

  @override
  int build() => 0;
}
''');
  }

  Future<void> test_privateField() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  int _privateField = 0;

  @override
  int build() => _privateField;
}
''');
  }

  Future<void> test_overrideGetter() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  @override
  int get state => 42;

  @override
  int build() => 0;
}
''');
  }

  Future<void> test_stateGetterNotFlagged() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;
}
''');
  }

  Future<void> test_publicMethodNotFlagged() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  void increment() => state++;

  @override
  int build() => 0;
}
''');
  }

  Future<void> test_staticFieldNotFlagged() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  static int staticField = 0;

  @override
  int build() => 0;
}
''');
  }

  Future<void> test_staticGetterNotFlagged() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  static int get staticGetter => 0;

  @override
  int build() => 0;
}
''');
  }

  Future<void> test_notANotifierClass() async {
    await assertNoDiagnostics(r'''
class RegularClass {
  int get publicGetter => 0;
  int publicField = 0;
}
''');
  }
}
