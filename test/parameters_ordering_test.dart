import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/parameters_ordering.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(ParametersOrderingTest));
}

@reflectiveTest
class ParametersOrderingTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = ParametersOrdering();
    super.setUp();

    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  parameters_ordering:\n    order: alphabetical\n',
    );
  }

  Future<void> test_unorderedNamedParameters() async {
    await assertDiagnostics(
      r'''
void f({
  String? zebra,
  String? apple,
  String? mango,
  String? cherry,
  String? banana,
}) {}
''',
      [lint(36, 5)],
    );
  }

  Future<void> test_orderedNamedParameters() async {
    await assertNoDiagnostics(r'''
void f({
  String? apple,
  String? banana,
  String? cherry,
  String? mango,
  String? zebra,
}) {}
''');
  }

  Future<void> test_positionalParametersAreNeverOrdered() async {
    await assertNoDiagnostics(r'''
void f(String zebra, String apple, String mango, String cherry, String banana) {}
''');
  }

  Future<void> test_shortSignatureIsBelowTheThreshold() async {
    await assertNoDiagnostics(r'''
void f({String? zebra, String? apple}) {}
''');
  }

  Future<void> test_requiredAndOptionalAreSortedAsSeparateGroups() async {
    await assertNoDiagnostics(r'''
void f({
  required String apple,
  required String zebra,
  String? banana,
  String? cherry,
  String? mango,
}) {}
''');
  }

  Future<void> test_unorderedWithinTheRequiredGroup() async {
    await assertDiagnostics(
      r'''
void f({
  required String zebra,
  required String apple,
  String? banana,
  String? cherry,
  String? mango,
}) {}
''',
      [lint(52, 5)],
    );
  }
}
