import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/prefer_named_parameters.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferNamedParametersTest);
    defineReflectiveTests(PreferNamedParametersBudgetTest);
  });
}

@reflectiveTest
class PreferNamedParametersTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferNamedParameters();
    super.setUp();
  }

  Future<void> test_threePositionalParameters() async {
    await assertDiagnostics(
      r'''
void move(int x, int y, int z) {}
''',
      [lint(9, 21)],
    );
  }

  // One or two positional parameters are usually the subject of the call.
  Future<void> test_twoPositionalIsFine() async {
    await assertNoDiagnostics(r'''
String slice(String value, int start) => value;
''');
  }

  Future<void> test_namedParametersAreFine() async {
    await assertNoDiagnostics(r'''
void move({int x = 0, int y = 0, int z = 0}) {}
''');
  }

  // The signature belongs to the supertype, so only the override is exempt —
  // the base declaration is the author's own and still reports, which is the
  // asymmetric half of this pair.
  Future<void> test_overrideIsExempt() async {
    await assertDiagnostics(
      r'''
class Base {
  void move(int x, int y, int z) {}
}

class Sub extends Base {
  @override
  void move(int x, int y, int z) {}
}
''',
      [lint(24, 21)],
    );
  }

  // A private constructor is not an API: it is reached from one place in the
  // same library, usually a factory assembling injected dependencies.
  Future<void> test_privateConstructorIsExempt() async {
    await assertNoDiagnostics(r'''
class Pipeline {
  const Pipeline._(this.a, this.b, this.c);

  final int a;
  final int b;
  final int c;
}
''');
  }

  // ...but a PUBLIC constructor is an API and still reports, which is the
  // asymmetric half of that exemption.
  Future<void> test_publicConstructorStillReports() async {
    await assertDiagnostics(
      r'''
class Pipeline {
  const Pipeline(this.a, this.b, this.c);

  final int a;
  final int b;
  final int c;
}
''',
      [lint(33, 24)],
    );
  }

  // dart_frog's route contract: the parameters are the URL's path segments in
  // order, so naming them is not the author's to decide.
  Future<void> test_frameworkEntrypointIsExempt() async {
    await assertNoDiagnostics(r'''
void onRequest(Object context, String organizerId, String leagueId) {}
''');
  }

  // An operator's parameters cannot be named.
  Future<void> test_operatorIsExempt() async {
    await assertNoDiagnostics(r'''
class Vector {
  Vector operator +(Vector other) => this;
}
''');
  }
}

/// `max_positional`, with the asymmetric pair.
@reflectiveTest
class PreferNamedParametersBudgetTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferNamedParameters();
    super.setUp();
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n'
          '  prefer_named_parameters:\n'
          '    max_positional: 1\n',
    );
  }

  // Two are silent by default and must report once the budget drops.
  Future<void> test_loweredBudgetReports() async {
    await assertDiagnostics(
      r'''
String slice(String value, int start) => value;
''',
      [lint(12, 25)],
    );
  }

  Future<void> test_oneIsStillSilent() async {
    await assertNoDiagnostics(r'''
String trim(String value) => value;
''');
  }
}
