import 'fpdart_stub.dart';
import 'many_lints_rule_test_base.dart';

export 'many_lints_rule_test_base.dart';

abstract class FpdartRuleTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    // Edge case: without the stub fpdart type checkers never resolve and every rule stays silent
    final fpdart = newPackage('fpdart');
    for (final MapEntry(key: path, value: source) in fpdartStubFiles.entries) {
      fpdart.addFile(path, source);
    }

    super.setUp();
  }
}
