import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_map_keys_contains.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidMapKeysContainsTest));
}

@reflectiveTest
class AvoidMapKeysContainsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMapKeysContains();
    super.setUp();
  }

  Future<void> test_keysContains_onMapLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  final map = {'a': 1, 'b': 2};
  map.keys.contains('a');
}
''',
      [lint(45, 22)],
    );
  }

  Future<void> test_keysContains_onMapVariable() async {
    await assertDiagnostics(
      r'''
void f(Map<String, int> map) {
  map.keys.contains('hello');
}
''',
      [lint(33, 26)],
    );
  }

  Future<void> test_containsKey_noLint() async {
    await assertNoDiagnostics(r'''
void f(Map<String, int> map) {
  map.containsKey('hello');
}
''');
  }

  Future<void> test_keysLength_noLint() async {
    await assertNoDiagnostics(r'''
void f(Map<String, int> map) {
  map.keys.length;
}
''');
  }

  Future<void> test_keysContains_onNonMap_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  Keys get keys => Keys();
}

class Keys {
  bool contains(Object? value) => false;
}

void f(Foo foo) {
  foo.keys.contains('a');
}
''');
  }

  Future<void> test_keysContains_nestedExpression() async {
    await assertDiagnostics(
      r'''
void f() {
  final maps = [<String, int>{}];
  maps.first.keys.contains('a');
}
''',
      [lint(47, 29)],
    );
  }
}
