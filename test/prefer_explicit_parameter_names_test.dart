import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/prefer_explicit_parameter_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferExplicitParameterNamesTest);
    defineReflectiveTests(PreferExplicitParameterNamesMinTest);
  });
}

@reflectiveTest
class PreferExplicitParameterNamesTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferExplicitParameterNames();
    super.setUp();
  }

  Future<void> test_unnamedParametersInTypedef() async {
    await assertDiagnostics(
      r'''
typedef OnChanged = void Function(String, int);
''',
      [lint(33, 13)],
    );
  }

  Future<void> test_namedParametersAreFine() async {
    await assertNoDiagnostics(r'''
typedef OnChanged = void Function(String label, int count);
''');
  }

  // A single-parameter function type is unambiguous from the type alone.
  Future<void> test_singleParameterIsExemptByDefault() async {
    await assertNoDiagnostics(r'''
typedef OnTap = void Function(String);
''');
  }

  Future<void> test_functionTypedParameterIsChecked() async {
    await assertDiagnostics(
      r'''
void listen(void Function(String, int) callback) {}
''',
      [lint(25, 13)],
    );
  }

  // A partially named signature is still missing names.
  Future<void> test_partiallyNamedStillReports() async {
    await assertDiagnostics(
      r'''
typedef OnChanged = void Function(String label, int);
''',
      [lint(33, 19)],
    );
  }
}

/// `min_parameters`, with the asymmetric pair.
@reflectiveTest
class PreferExplicitParameterNamesMinTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferExplicitParameterNames();
    super.setUp();
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n'
          '  prefer_explicit_parameter_names:\n'
          '    min_parameters: 1\n',
    );
  }

  // Silent by default, reports once the threshold drops to one.
  Future<void> test_singleParameterReportsWhenConfigured() async {
    await assertDiagnostics(
      r'''
typedef OnTap = void Function(String);
''',
      [lint(29, 8)],
    );
  }

  Future<void> test_namedSingleParameterIsStillSilent() async {
    await assertNoDiagnostics(r'''
typedef OnTap = void Function(String label);
''');
  }
}
