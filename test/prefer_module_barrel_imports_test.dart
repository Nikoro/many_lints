import 'package:many_lints/src/rules/prefer_module_barrel_imports.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferModuleBarrelImportsTest),
  );
}

@reflectiveTest
class PreferModuleBarrelImportsTest extends ManyLintsRuleTest {
  @override
  String get testFileName => _fileName;

  String _fileName = 'orders/page.dart';
  bool _outsideLib = false;

  @override
  String get testPackageLibPath =>
      _outsideLib ? '$testPackageRootPath/test' : super.testPackageLibPath;

  @override
  void setUp() {
    rule = PreferModuleBarrelImports();
    newPackage('external')
      ..addFile('lib/internal.dart', 'class External {}')
      ..addFile('lib/external.dart', "export 'internal.dart';");
    super.setUp();
    newFile('$testPackageLibPath/users/model.dart', 'class User {}');
    newFile('$testPackageLibPath/users/users.dart', "export 'model.dart';");
    newFile('$testPackageLibPath/orders/model.dart', 'class Order {}');
  }

  Future<void> test_crossModuleRelative() async {
    await assertDiagnostics("import '../users/model.dart';\nUser? user;", [
      lint(7, 21),
    ]);
  }

  Future<void> test_crossModulePackage() async {
    await assertDiagnostics(
      "import 'package:test/users/model.dart';\nUser? user;",
      [lint(7, 31)],
    );
  }

  Future<void> test_ownModule() async {
    await assertNoDiagnostics("import 'model.dart';\nOrder? order;");
  }

  Future<void> test_barrel() async {
    await assertNoDiagnostics("import '../users/users.dart';\nUser? user;");
  }

  Future<void> test_prefixAndCombinator() async {
    await assertDiagnostics(
      "import '../users/model.dart' as users show User;\nusers.User? user;",
      [lint(7, 21)],
    );
  }

  Future<void> test_conditionalBranch() async {
    await assertDiagnostics(
      "import '../users/users.dart' if (dart.library.html) '../users/model.dart';\nUser? user;",
      [lint(52, 21)],
    );
  }

  Future<void> test_missingBarrelStillReports() async {
    newFile('$testPackageLibPath/products/model.dart', 'class Product {}');
    await assertDiagnostics(
      "import '../products/model.dart';\nProduct? product;",
      [lint(7, 24)],
    );
  }

  Future<void> test_reexportCycleDoesNotRecurse() async {
    newFile(
      '$testPackageLibPath/users/users.dart',
      "export 'model.dart';\nexport '../orders/page.dart';",
    );
    await assertNoDiagnostics("import '../users/users.dart';\nUser? user;");
  }

  Future<void> test_externalPackageIgnoredByDefault() async {
    await assertNoDiagnostics(
      "import 'package:external/internal.dart';\nExternal? value;",
    );
  }

  Future<void> test_externalPackageEntryPoint() async {
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  prefer_module_barrel_imports:\n    package_entry_points: [package:external/external.dart]\n',
    );
    await assertDiagnostics(
      "import 'package:external/internal.dart';\nExternal? value;",
      [lint(7, 32)],
    );
  }

  Future<void> test_nestedModuleRoots() async {
    newFile('$testPackageLibPath/features/users/model.dart', 'class User {}');
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  prefer_module_barrel_imports:\n    module_roots: [lib, lib/features]\n',
    );
    await assertDiagnostics(
      "import '../features/users/model.dart';\nUser? user;",
      [lint(7, 30)],
    );
  }

  Future<void> test_externalBarrelAllowed() async {
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  prefer_module_barrel_imports:\n    package_entry_points: [package:external/external.dart]\n',
    );
    await assertNoDiagnostics(
      "import 'package:external/external.dart';\nExternal? value;",
    );
  }

  Future<void> test_ownPackageUmbrellaRejectedInsideLib() async {
    newFile('$testPackageLibPath/test.dart', "export 'users/users.dart';");
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  prefer_module_barrel_imports:\n    package_entry_points: [package:test/test.dart]\n',
    );
    await assertDiagnostics("import 'package:test/test.dart';\nUser? user;", [
      lint(7, 24),
    ]);
  }

  Future<void> test_emptyRootsKeepDefault() async {
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  prefer_module_barrel_imports:\n    module_roots: []\n',
    );
    await assertDiagnostics("import '../users/model.dart';\nUser? user;", [
      lint(7, 21),
    ]);
  }

  Future<void> test_malformedRootsKeepDefault() async {
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  prefer_module_barrel_imports:\n    module_roots: 42\n',
    );
    await assertDiagnostics("import '../users/model.dart';\nUser? user;", [
      lint(7, 21),
    ]);
  }

  Future<void> test_excludeMatching() async {
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  prefer_module_barrel_imports:\n    exclude: [lib/orders/**]\n',
    );
    await assertNoDiagnostics("import '../users/model.dart';\nUser? user;");
  }

  Future<void> test_excludeOtherPathStillReports() async {
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  prefer_module_barrel_imports:\n    exclude: [test/**]\n',
    );
    await assertDiagnostics("import '../users/model.dart';\nUser? user;", [
      lint(7, 21),
    ]);
  }

  Future<void> test_testUsesConfiguredPackageEntryPoint() async {
    _outsideLib = true;
    _fileName = 'page.dart';
    newFile('$testPackageRootPath/lib/test.dart', "export 'users/users.dart';");
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  prefer_module_barrel_imports:\n    package_entry_points: [package:test/test.dart]\n',
    );
    await assertDiagnostics(
      "import 'package:test/users/model.dart';\nUser? user;",
      [lint(7, 31)],
    );
  }

  Future<void> test_packageEntryPointAllowedFromTests() async {
    _outsideLib = true;
    _fileName = 'page.dart';
    newFile('$testPackageRootPath/lib/test.dart', "export 'users/users.dart';");
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  prefer_module_barrel_imports:\n    package_entry_points: [package:test/test.dart]\n',
    );
    await assertNoDiagnostics("import 'package:test/test.dart';\nUser? user;");
  }

  Future<void> test_generatedImportIgnored() async {
    _fileName = 'orders/page.g.dart';
    await assertNoDiagnostics("import '../users/model.dart';\nUser? user;");
  }
}
