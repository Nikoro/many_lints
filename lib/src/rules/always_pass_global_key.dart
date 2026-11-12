import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

class AlwaysPassGlobalKey extends ManyLintsRule {
  static const LintCode code = LintCode(
    'always_pass_global_key',
    "A 'GlobalKey' is created inside 'build'.",
    correctionMessage:
        'Store the key in a State field so it keeps its identity across '
        'rebuilds, otherwise the subtree loses its state every time.',
  );

  AlwaysPassGlobalKey()
    : super(
        name: 'always_pass_global_key',
        description:
            'Warns when a GlobalKey is constructed inside build, discarding '
            'the subtree state on every rebuild.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AlwaysPassGlobalKey rule;

  _Visitor(this.rule);

  static const _globalKeyChecker = TypeChecker.fromName(
    'GlobalKey',
    packageName: 'flutter',
  );

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return;

    final finder = _GlobalKeyFinder(rule, _globalKeyChecker);
    node.body.accept(finder);
  }
}

class _GlobalKeyFinder extends RecursiveAstVisitor<void> {
  final AlwaysPassGlobalKey rule;
  final TypeChecker checker;

  _GlobalKeyFinder(this.rule, this.checker);

  void _check(Expression node) {
    final type = node.staticType;
    if (type == null) return;
    if (!checker.isAssignableFromType(type)) return;

    rule.reportAtNode(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Edge case: without type arguments a constructor call parses as a method invocation
    if (node.methodName.name == 'GlobalKey') _check(node);
    super.visitMethodInvocation(node);
  }
}
