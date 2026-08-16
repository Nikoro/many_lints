import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/pattern_fields_ordering.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PatternFieldsOrderingTest));
}

@reflectiveTest
class PatternFieldsOrderingTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PatternFieldsOrdering();
    super.setUp();

    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  pattern_fields_ordering:\n    order: alphabetical\n',
    );
  }

  Future<void> test_unorderedObjectPatternFields() async {
    await assertDiagnostics(
      r'''
class P {
  final int apple = 0;
  final int zebra = 0;
}

void f(Object o) {
  if (o case P(zebra: final z, apple: final a)) {
    print('$z$a');
  }
}
''',
      [lint(109, 14)],
    );
  }

  Future<void> test_orderedObjectPatternFields() async {
    await assertNoDiagnostics(r'''
class P {
  final int apple = 0;
  final int zebra = 0;
}

void f(Object o) {
  if (o case P(apple: final a, zebra: final z)) {
    print('$a$z');
  }
}
''');
  }

  Future<void> test_positionalRecordPatternIsLeftAlone() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  if (o case (final b, final a)) {
    print('$b$a');
  }
}
''');
  }

  Future<void> test_singleField() async {
    await assertNoDiagnostics(r'''
class P {
  final int zebra = 0;
}

void f(Object o) {
  if (o case P(zebra: final z)) {
    print('$z');
  }
}
''');
  }
}
