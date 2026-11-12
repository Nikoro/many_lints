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

  Future<void> test_fileNameIsLeftToTheSdkFileNamesLint() async {
    await assertNoDiagnostics(r'''
class UserRepository {}
''');
  }
}

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
