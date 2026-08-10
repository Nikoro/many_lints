import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/notifier_build.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(NotifierBuildTest));
}

@reflectiveTest
class NotifierBuildTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = NotifierBuild();

    newPackage('riverpod_annotation').addFile(
      'lib/riverpod_annotation.dart',
      r'''
final class Riverpod {
  const Riverpod({this.keepAlive = false, this.dependencies});
  final bool keepAlive;
  final List<Object>? dependencies;
}

const riverpod = Riverpod();
''',
    );

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_annotatedClassWithoutBuild() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class Counter {}
''',
      [lint(80, 7)],
    );
  }

  Future<void> test_annotatedClassWithOtherMembersOnly() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class Counter {
  int get value => 0;
}
''',
      [lint(80, 7)],
    );
  }

  Future<void> test_constructorFormAnnotation() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@Riverpod(keepAlive: true)
class Counter {}
''',
      [lint(97, 7)],
    );
  }

  // --- Negative cases: should not trigger lint ---

  Future<void> test_annotatedClassWithBuild() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class Counter {
  int build() => 0;
}
''');
  }

  Future<void> test_unannotatedClassWithoutBuild() async {
    await assertNoDiagnostics(r'''
class Counter {}
''');
  }

  Future<void> test_annotatedFunctionNotFlagged() async {
    // Functional providers have no build method by design.
    await assertNoDiagnostics(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int counter(Object ref) => 0;
''');
  }
}
