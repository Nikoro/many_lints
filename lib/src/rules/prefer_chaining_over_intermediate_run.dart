import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

class PreferChainingOverIntermediateRun extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_chaining_over_intermediate_run',
    "This body runs {0} fpdart pipelines separately.",
    correctionMessage:
        "Chain them with 'flatMap' and run once at the boundary, so a failure "
        'short-circuits the rest instead of being unwrapped by hand.',
  );

  PreferChainingOverIntermediateRun()
    : super(
        name: 'prefer_chaining_over_intermediate_run',
        description:
            'Warns when a function body calls run() on several fpdart '
            'pipelines instead of chaining them and running once.',
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
    registry.addFunctionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferChainingOverIntermediateRun rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _check(node.body, node.name);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.body, node.name);

  void _check(FunctionBody body, Token name) {
    final collector = _RunCallCollector();
    body.accept(collector);

    final minSequence = rule.config.intOption('min_sequence', defaultValue: 2);
    if (collector.calls.length < minSequence) return;

    rule.reportAtToken(name, arguments: ['${collector.calls.length}']);
  }
}

class _RunCallCollector extends RecursiveAstVisitor<void> {
  final calls = <MethodInvocation>[];

  // Edge case: a closure runs its own pipeline, so its `.run()` calls are not the member's
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'run') {
      final targetType = node.realTarget?.staticType;
      if (targetType != null &&
          lazyFpdartChecker.isAssignableFromType(targetType)) {
        calls.add(node);
      }
    }

    super.visitMethodInvocation(node);
  }
}
