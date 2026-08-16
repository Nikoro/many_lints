import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/arguments_ordering.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(ArgumentsOrderingTest));
}

@reflectiveTest
class ArgumentsOrderingTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = ArgumentsOrdering();
    super.setUp();

    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  arguments_ordering:\n    order: alphabetical\n',
    );
  }

  Future<void> test_unorderedNamedArguments() async {
    await assertDiagnostics(
      r'''
void f({int? apple, int? banana, int? cherry, int? mango, int? zebra}) {}

void g() {
  f(zebra: 1, apple: 2, banana: 3, cherry: 4, mango: 5);
}
''',
      [lint(100, 5)],
    );
  }

  Future<void> test_orderedNamedArguments() async {
    await assertNoDiagnostics(r'''
void f({int? apple, int? banana, int? cherry, int? mango, int? zebra}) {}

void g() {
  f(apple: 1, banana: 2, cherry: 3, mango: 4, zebra: 5);
}
''');
  }

  Future<void> test_positionalArgumentsAreNeverOrdered() async {
    // Their order is the call's meaning; reordering changes what it does.
    await assertNoDiagnostics(r'''
void f(int a, int b, int c, int d, int e) {}

void g() {
  f(5, 4, 3, 2, 1);
}
''');
  }

  Future<void> test_shortCallIsBelowTheThreshold() async {
    await assertNoDiagnostics(r'''
void f({int? zebra, int? apple}) {}

void g() {
  f(zebra: 1, apple: 2);
}
''');
  }
}
