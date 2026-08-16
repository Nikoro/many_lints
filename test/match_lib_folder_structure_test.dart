import 'package:many_lints/src/rules/match_lib_folder_structure.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MatchLibFolderStructureTest);
    defineReflectiveTests(MatchLibFolderStructureValidFolderTest);
    defineReflectiveTests(MatchLibFolderStructureOutsideLibTest);
  });
}

@reflectiveTest
class MatchLibFolderStructureTest extends ManyLintsRuleTest {
  @override
  String get testFileName => 'dataSources/user_repository.dart';

  @override
  void setUp() {
    rule = MatchLibFolderStructure();
    super.setUp();
  }

  Future<void> test_camelCaseFolderIsReported() async {
    await assertDiagnostics(
      r'''
class UserRepository {}
''',
      [lint(0, 0)],
    );
  }
}

/// The asymmetric positive: a correctly named folder must stay silent.
@reflectiveTest
class MatchLibFolderStructureValidFolderTest extends ManyLintsRuleTest {
  @override
  String get testFileName => 'data_sources/user_repository.dart';

  @override
  void setUp() {
    rule = MatchLibFolderStructure();
    super.setUp();
  }

  Future<void> test_snakeCaseFolderIsSilent() async {
    await assertNoDiagnostics(r'''
class UserRepository {}
''');
  }

  // The file's own name is the SDK's `file_names` territory, not this rule's.
  Future<void> test_fileNameIsNotChecked() async {
    await assertNoDiagnostics(r'''
class UserRepository {}
''');
  }
}

/// The rule is scoped to `lib/`; the same folder name elsewhere is silent.
@reflectiveTest
class MatchLibFolderStructureOutsideLibTest extends ManyLintsRuleTest {
  @override
  String get testPackageLibPath => '$testPackageRootPath/test';

  @override
  String get testFileName => 'dataSources/user_repository_test.dart';

  @override
  void setUp() {
    rule = MatchLibFolderStructure();
    super.setUp();
  }

  Future<void> test_folderOutsideLibIsSilent() async {
    await assertNoDiagnostics(r'''
class UserRepository {}
''');
  }
}
