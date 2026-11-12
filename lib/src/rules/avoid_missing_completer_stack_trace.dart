import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

class AvoidMissingCompleterStackTrace extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_missing_completer_stack_trace',
    "'completeError' is called without a stack trace.",
    correctionMessage:
        'Pass the stack trace as the second argument so the error stays '
        'traceable to where it was thrown.',
  );

  AvoidMissingCompleterStackTrace()
    : super(
        name: 'avoid_missing_completer_stack_trace',
        description:
            'Warns when Completer.completeError is called without passing a '
            'stack trace.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidMissingCompleterStackTrace rule;

  _Visitor(this.rule);

  static const _completerChecker = TypeChecker.fromUrl('dart:async#Completer');

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'completeError') return;

    if (node.argumentList.arguments.length >= 2) return;

    final targetType = node.realTarget?.staticType;
    if (targetType == null) return;
    if (!_completerChecker.isAssignableFromType(targetType)) return;

    final requireInsideCatch = rule.config.boolOption(
      'require_inside_catch',
      defaultValue: true,
    );

    if (requireInsideCatch) {
      final catchClause = _enclosingCatchClause(node);
      // Edge case: a bare catch (e) has no stack trace in scope, so a report could not be acted on
      if (catchClause?.stackTraceParameter == null) return;
    }

    rule.reportAtNode(node);
  }

  CatchClause? _enclosingCatchClause(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is CatchClause) return current;
      // Edge case: a closure defined in a catch block is not credited with its trace
      if (current is FunctionExpression || current is MethodDeclaration) {
        return null;
      }
    }

    return null;
  }
}
