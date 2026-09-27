import 'package:many_lints/src/rules/require_module_barrel.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(RequireModuleBarrelTest));
}

@reflectiveTest
class RequireModuleBarrelTest extends ManyLintsRuleTest {
  @override
  String get testFileName => _fileName;

  String _fileName = 'orders/model.dart';

  @override
  void setUp() {
    rule = RequireModuleBarrel();
    super.setUp();
  }

  Future<void> test_missingBarrel() async {
    await assertDiagnostics('class Order {}', [lint(0, 5)]);
  }

  Future<void> test_existingBarrel() async {
    newFile('$testPackageLibPath/orders/orders.dart', "export 'model.dart';");
    await assertNoDiagnostics('class Order {}');
  }

  Future<void> test_excludedModule() async {
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  require_module_barrel:\n    exclude: [lib/orders/**]\n',
    );
    await assertNoDiagnostics('class Order {}');
  }

  Future<void> test_otherModuleExcluded() async {
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  require_module_barrel:\n    exclude: [lib/users/**]\n',
    );
    await assertDiagnostics('class Order {}', [lint(0, 5)]);
  }

  Future<void> test_generatedFileIgnored() async {
    _fileName = 'orders/model.g.dart';
    await assertNoDiagnostics('class GeneratedOrder {}');
  }

  Future<void> test_rootFileIsNotAModule() async {
    _fileName = 'main.dart';
    await assertNoDiagnostics('class App {}');
  }

  Future<void> test_partDoesNotRequireItsOwnBarrel() async {
    newFile('$testPackageLibPath/root.dart', "part 'orders/model.dart';");
    await assertNoDiagnostics("part of '../root.dart';\nclass Order {}");
  }
}
