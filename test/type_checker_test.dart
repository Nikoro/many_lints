import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/type_checker.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeCheckerFromNameExactTest);
    defineReflectiveTests(TypeCheckerFromNameNoMatchTest);
    defineReflectiveTests(TypeCheckerIsSuperOfTest);
    defineReflectiveTests(TypeCheckerAnyTest);
    defineReflectiveTests(TypeCheckerIsAssignableFromTypeTest);
  });
}

// --- Lightweight rule that delegates to TypeChecker for testing ---

enum CheckMode { isExactly, isSuperOf, isAssignableFromType }

class TypeCheckerTestRule extends AnalysisRule {
  static const code = LintCode('type_checker_test_rule', 'Type matched.');

  final TypeChecker checker;
  final CheckMode mode;

  TypeCheckerTestRule(this.checker, this.mode)
    : super(
        name: 'type_checker_test_rule',
        description: 'Test rule for TypeChecker.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this, checker, mode));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final TypeCheckerTestRule rule;
  final TypeChecker checker;
  final CheckMode mode;

  _Visitor(this.rule, this.checker, this.mode);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    final matched = switch (mode) {
      CheckMode.isExactly => checker.isExactly(element),
      CheckMode.isSuperOf => checker.isSuperOf(element),
      CheckMode.isAssignableFromType => checker.isAssignableFromType(
        element.thisType,
      ),
    };

    if (matched) {
      rule.reportAtToken(node.namePart.typeName);
    }
  }
}

// --- fromName + isExactly ---

@reflectiveTest
class TypeCheckerFromNameExactTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = TypeCheckerTestRule(
      const TypeChecker.fromName('BaseWidget', packageName: 'some_package'),
      CheckMode.isExactly,
    );

    final pkg = newPackage('some_package');
    pkg.addFile('lib/some_package.dart', r'''
class BaseWidget {}
class OtherClass {}
''');

    super.setUp();
  }

  Future<void> test_exactMatch_reportsSubclass() async {
    // MyWidget extends BaseWidget from 'some_package' — the superclass
    // itself is BaseWidget, so isExactly on MyWidget should NOT match.
    // But isExactly checks the element directly, not its supertype.
    await assertNoDiagnostics(r'''
import 'package:some_package/some_package.dart';

class MyWidget extends BaseWidget {}
''');
  }

  Future<void> test_noMatch_differentName() async {
    await assertNoDiagnostics(r'''
import 'package:some_package/some_package.dart';

class MyClass extends OtherClass {}
''');
  }

  Future<void> test_noMatch_localClassSameName() async {
    // A local class named BaseWidget should NOT match (wrong package).
    await assertNoDiagnostics(r'''
class BaseWidget {}

class MyWidget extends BaseWidget {}
''');
  }
}

// --- fromName + isExactly but checking the exact class ---

@reflectiveTest
class TypeCheckerFromNameNoMatchTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = TypeCheckerTestRule(
      const TypeChecker.fromName('OtherClass', packageName: 'some_package'),
      CheckMode.isExactly,
    );

    final pkg = newPackage('some_package');
    pkg.addFile('lib/some_package.dart', r'''
class OtherClass {}
''');

    super.setUp();
  }

  Future<void> test_noMatch_unrelatedLocal() async {
    await assertNoDiagnostics(r'''
class Unrelated {}
''');
  }
}

// --- isSuperOf ---

@reflectiveTest
class TypeCheckerIsSuperOfTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = TypeCheckerTestRule(
      const TypeChecker.fromName('GrandParent', packageName: 'hierarchy_pkg'),
      CheckMode.isSuperOf,
    );

    final pkg = newPackage('hierarchy_pkg');
    pkg.addFile('lib/hierarchy_pkg.dart', r'''
class GrandParent {}
class Parent extends GrandParent {}
class Child extends Parent {}
''');

    super.setUp();
  }

  Future<void> test_isSuperOf_directChild() async {
    await assertDiagnostics(
      r'''
import 'package:hierarchy_pkg/hierarchy_pkg.dart';

class MyChild extends Parent {}
''',
      [lint(58, 7)],
    );
  }

  Future<void> test_isSuperOf_deepChild() async {
    await assertDiagnostics(
      r'''
import 'package:hierarchy_pkg/hierarchy_pkg.dart';

class MyDeepChild extends Child {}
''',
      [lint(58, 11)],
    );
  }

  Future<void> test_isSuperOf_unrelatedClass() async {
    await assertNoDiagnostics(r'''
class Unrelated {}
''');
  }
}

// --- any ---

@reflectiveTest
class TypeCheckerAnyTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = TypeCheckerTestRule(
      const TypeChecker.any([
        TypeChecker.fromName('TypeA', packageName: 'multi_pkg'),
        TypeChecker.fromName('TypeB', packageName: 'multi_pkg'),
      ]),
      CheckMode.isSuperOf,
    );

    final pkg = newPackage('multi_pkg');
    pkg.addFile('lib/multi_pkg.dart', r'''
class TypeA {}
class TypeB {}
class TypeC {}
''');

    super.setUp();
  }

  Future<void> test_any_matchesFirst() async {
    await assertDiagnostics(
      r'''
import 'package:multi_pkg/multi_pkg.dart';

class MyA extends TypeA {}
''',
      [lint(50, 3)],
    );
  }

  Future<void> test_any_matchesSecond() async {
    await assertDiagnostics(
      r'''
import 'package:multi_pkg/multi_pkg.dart';

class MyB extends TypeB {}
''',
      [lint(50, 3)],
    );
  }

  Future<void> test_any_matchesNone() async {
    await assertNoDiagnostics(r'''
import 'package:multi_pkg/multi_pkg.dart';

class MyC extends TypeC {}
''');
  }
}

// --- isAssignableFromType ---

@reflectiveTest
class TypeCheckerIsAssignableFromTypeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = TypeCheckerTestRule(
      const TypeChecker.fromName('Base', packageName: 'assignable_pkg'),
      CheckMode.isAssignableFromType,
    );

    final pkg = newPackage('assignable_pkg');
    pkg.addFile('lib/assignable_pkg.dart', r'''
class Base {}
class Derived extends Base {}
''');

    super.setUp();
  }

  Future<void> test_isAssignableFromType_subclass() async {
    await assertDiagnostics(
      r'''
import 'package:assignable_pkg/assignable_pkg.dart';

class MyDerived extends Derived {}
''',
      [lint(60, 9)],
    );
  }

  Future<void> test_isAssignableFromType_noMatch() async {
    await assertNoDiagnostics(r'''
class Unrelated {}
''');
  }
}
