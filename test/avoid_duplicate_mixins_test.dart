import 'package:many_lints/src/rules/avoid_duplicate_mixins.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidDuplicateMixinsTest));
}

@reflectiveTest
class AvoidDuplicateMixinsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateMixins();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_duplicateMixinOnClass() async {
    await assertDiagnostics(
      r'''
mixin M {}

class A with M, M {}
''',
      [lint(28, 1)],
    );
  }

  Future<void> test_duplicateAmongSeveralMixins() async {
    await assertDiagnostics(
      r'''
mixin M {}
mixin N {}

class A with M, N, M {}
''',
      [lint(42, 1)],
    );
  }

  Future<void> test_duplicateOnEnum() async {
    await assertDiagnostics(
      r'''
mixin M {}

enum E with M, M { a, b }
''',
      [lint(27, 1)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_distinctMixins() async {
    await assertNoDiagnostics(r'''
mixin M {}
mixin N {}

class A with M, N {}
''');
  }

  Future<void> test_singleMixin() async {
    await assertNoDiagnostics(r'''
mixin M {}

class A with M {}
''');
  }

  Future<void> test_sameMixinOnDifferentClasses() async {
    await assertNoDiagnostics(r'''
mixin M {}

class A with M {}
class B with M {}
''');
  }

  // ---- Edge cases ----

  Future<void> test_mixinAlsoOnSuperclassIsNotADuplicate() async {
    // Re-applying a mixin the superclass already has is a different question:
    // it does change the linearization order.
    await assertNoDiagnostics(r'''
mixin M {}

class Base with M {}
class Derived extends Base with M {}
''');
  }

  Future<void> test_repeatedGenericMixinWithSameArguments() async {
    // `M<int>, M<String>` cannot be written at all — the compiler rejects it
    // as conflicting generic interfaces — so the only reachable generic case
    // is the same instantiation twice, which is a duplicate.
    await assertDiagnostics(
      r'''
mixin M<T> {}

class A with M<int>, M<int> {}
''',
      [lint(36, 6)],
    );
  }
}
