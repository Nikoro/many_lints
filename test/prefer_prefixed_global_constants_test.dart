import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/prefer_prefixed_global_constants.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferPrefixedGlobalConstantsTest),
  );
}

@reflectiveTest
class PreferPrefixedGlobalConstantsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferPrefixedGlobalConstants();
    super.setUp();
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  prefer_prefixed_global_constants:\n    prefix: k\n',
    );
  }

  Future<void> test_unprefixedGlobalConstant() async {
    await assertDiagnostics(
      r'''
const defaultTimeout = 30;
''',
      [lint(6, 14)],
    );
  }

  Future<void> test_prefixedGlobalConstant() async {
    await assertNoDiagnostics(r'''
const kDefaultTimeout = 30;
''');
  }

  // A private constant cannot collide outside its library, which is the
  // problem the prefix exists to solve.
  Future<void> test_privateConstantIsSkipped() async {
    await assertNoDiagnostics(r'''
const _defaultTimeout = 30;
''');
  }

  Future<void> test_nonConstantIsSkipped() async {
    await assertNoDiagnostics(r'''
final defaultTimeout = 30;
''');
  }
}
