import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_build_context_in_providers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidBuildContextInProvidersTest),
  );
}

@reflectiveTest
class AvoidBuildContextInProvidersTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidBuildContextInProviders();

    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
''');

    newPackage('riverpod_annotation').addFile(
      'lib/riverpod_annotation.dart',
      r'''
final class Riverpod {
  const Riverpod({this.keepAlive = false});
  final bool keepAlive;
}

const riverpod = Riverpod();

class Ref {}
''',
    );

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_functionalProviderWithBuildContext() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int example(Ref ref, BuildContext context) => 0;
''',
      [lint(134, 20)],
    );
  }

  Future<void> test_classProviderMethodWithBuildContext() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class Example {
  int build(BuildContext context) => 0;
}
''',
      [lint(141, 20)],
    );
  }

  // --- Negative cases: should not trigger lint ---

  Future<void> test_functionalProviderWithoutBuildContext() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int example(Ref ref) => 0;
''');
  }

  Future<void> test_unannotatedFunctionWithBuildContext() async {
    // An ordinary function is free to take a BuildContext.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

int example(BuildContext context) => 0;
''');
  }

  Future<void> test_unannotatedClassWithBuildContext() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Example {
  int build(BuildContext context) => 0;
}
''');
  }
}
