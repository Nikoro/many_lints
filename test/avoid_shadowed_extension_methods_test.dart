import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_shadowed_extension_methods.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidShadowedExtensionMethodsTest),
  );
}

@reflectiveTest
class AvoidShadowedExtensionMethodsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidShadowedExtensionMethods();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_shadowsCoreMethod() async {
    await assertDiagnostics(
      r'''
extension StringExtension on String {
  String toUpperCase() => '!';
}
''',
      [lint(47, 11)],
    );
  }

  Future<void> test_shadowsUserMethod() async {
    await assertDiagnostics(
      r'''
class Model {
  void save() {}
}

extension ModelExtension on Model {
  void save() {}
}
''',
      [lint(77, 4)],
    );
  }

  Future<void> test_shadowsInheritedMethod() async {
    await assertDiagnostics(
      r'''
class Base {
  void save() {}
}

class Model extends Base {}

extension ModelExtension on Model {
  void save() {}
}
''',
      [lint(105, 4)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_uniqueMethodName() async {
    await assertNoDiagnostics(r'''
extension StringExtension on String {
  String shout() => '$this!';
}
''');
  }

  Future<void> test_uniqueGetterName() async {
    await assertNoDiagnostics(r'''
extension StringExtension on String {
  bool get isShouted => length > 0;
}
''');
  }

  Future<void> test_staticMemberIsIgnored() async {
    await assertNoDiagnostics(r'''
class Model {
  void save() {}
}

extension ModelExtension on Model {
  static void save() {}
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_objectMembersAreIgnored() async {
    await assertNoDiagnostics(r'''
class Model {}

extension ModelExtension on Model {
  String describe() => 'model';
}
''');
  }

  Future<void> test_shadowedGetterIsReported() async {
    await assertDiagnostics(
      r'''
class Model {
  int get id => 1;
}

extension ModelExtension on Model {
  int get id => 2;
}
''',
      [lint(82, 2)],
    );
  }
}
