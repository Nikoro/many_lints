import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/initializers_ordering.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(InitializersOrderingTest));
}

@reflectiveTest
class InitializersOrderingTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = InitializersOrdering();
    super.setUp();

    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  initializers_ordering: true\n',
    );
  }

  // The default follows the class's own field declaration order, which is a
  // decision the class already made.
  Future<void> test_initializersOutOfFieldOrder() async {
    await assertDiagnostics(
      r'''
class C {
  final int a;
  final int b;

  C(int x, int y) : b = y, a = x;
}
''',
      [lint(68, 1)],
    );
  }

  Future<void> test_initializersFollowFieldOrder() async {
    await assertNoDiagnostics(r'''
class C {
  final int a;
  final int b;

  C(int x, int y) : a = x, b = y;
}
''');
  }

  Future<void> test_singleInitializer() async {
    await assertNoDiagnostics(r'''
class C {
  final int a;

  C(int x) : a = x;
}
''');
  }

  Future<void> test_superAndAssertAreSkipped() async {
    // Their position is fixed by the language, not by this rule.
    await assertNoDiagnostics(r'''
class B {
  B(int v);
}

class C extends B {
  final int a;

  C(int x) : a = x, assert(x > 0), super(x);
}
''');
  }
}
