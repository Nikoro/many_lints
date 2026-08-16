import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/record_fields_ordering.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(RecordFieldsOrderingTest));
}

@reflectiveTest
class RecordFieldsOrderingTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = RecordFieldsOrdering();
    super.setUp();

    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  record_fields_ordering:\n    order: alphabetical\n',
    );
  }

  Future<void> test_unorderedNamedFields() async {
    await assertDiagnostics(
      r'''
typedef T = ({int zebra, int apple});
''',
      [lint(29, 5)],
    );
  }

  Future<void> test_orderedNamedFields() async {
    await assertNoDiagnostics(r'''
typedef T = ({int apple, int zebra});
''');
  }

  Future<void> test_positionalFieldsAreNeverOrdered() async {
    // Position is identity for a positional field: reordering makes a
    // different type.
    await assertNoDiagnostics(r'''
typedef T = (int, String, bool);
''');
  }

  Future<void> test_singleNamedField() async {
    await assertNoDiagnostics(r'''
typedef T = ({int zebra});
''');
  }
}
