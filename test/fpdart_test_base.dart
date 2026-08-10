import 'fpdart_stub.dart';
import 'many_lints_rule_test_base.dart';

export 'many_lints_rule_test_base.dart';

/// Base class for the fpdart rule tests.
///
/// fpdart is not part of the mock SDK these tests analyze against, so without
/// a stand-in package every `TypeChecker` in `fpdart_type_checkers.dart` fails
/// to resolve and each rule silently reports nothing — which would make every
/// "no diagnostics" assertion pass while proving nothing.
///
/// The stub lives in [fpdartStubFiles], shared with the fix output tests so
/// the two cannot drift apart. See that declaration for why its multi-file
/// layout matters.
abstract class FpdartRuleTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    final fpdart = newPackage('fpdart');
    for (final MapEntry(key: path, value: source) in fpdartStubFiles.entries) {
      fpdart.addFile(path, source);
    }

    super.setUp();
  }
}
