import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferForLoopInChildren extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_for_loop_in_children',
    'Prefer using a for-loop instead of functional list building.',
    correctionMessage:
        'Use collection-for syntax: [for (final item in items) Widget(item)].',
  );

  PreferForLoopInChildren()
    : super(
        name: 'prefer_for_loop_in_children',
        description:
            'Warns when .map().toList(), List.generate(), .fold(), or '
            'spread with .map() are used to build widget lists instead of '
            'collection-for syntax.',
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
    registry.addInstanceCreationExpression(this, visitor);
    registry.addListLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferForLoopInChildren rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    if (methodName == 'toList') {
      _checkMapToList(node);
      return;
    }

    if (methodName == 'fold') {
      _checkFold(node);
      return;
    }

    // Edge case: List.generate parses as a method call without type arguments
    if (methodName == 'generate') {
      _checkUntypedListGenerate(node);
      return;
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    if (constructorName.name?.name == 'generate') {
      final typeName = constructorName.type.name.lexeme;
      if (typeName == 'List') {
        final args = node.argumentList.arguments;
        if (args.length >= 2 && args[1] is FunctionExpression) {
          rule.reportAtNode(node);
        }
      }
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    for (final element in node.elements) {
      if (element is SpreadElement) {
        _checkSpreadMap(element);
      }
    }
  }

  void _checkMapToList(MethodInvocation node) {
    final isReportedAsSpread = node.parent is SpreadElement;
    if (isReportedAsSpread) return;

    final target = node.target;
    if (target is! MethodInvocation) return;
    if (target.methodName.name != 'map') return;

    final args = target.argumentList.arguments;
    if (args.isEmpty) return;
    if (args.first is! FunctionExpression) return;

    rule.reportAtNode(node);
  }

  void _checkUntypedListGenerate(MethodInvocation node) {
    final target = node.target;
    if (target is! SimpleIdentifier) return;
    if (target.name != 'List') return;

    final element = target.element;
    if (element == null) return;
    final library = element.library;
    if (library == null || !library.identifier.startsWith('dart:core')) return;

    final args = node.argumentList.arguments;
    if (args.length < 2) return;
    if (args[1] is! FunctionExpression) return;

    rule.reportAtNode(node);
  }

  void _checkFold(MethodInvocation node) {
    final args = node.argumentList.arguments;
    if (args.length < 2) return;

    final seed = args.first;
    if (seed is! ListLiteral) return;
    if (seed.elements.isNotEmpty) return;

    final combine = args[1];
    if (combine is! FunctionExpression) return;

    rule.reportAtNode(node);
  }

  void _checkSpreadMap(SpreadElement spread) {
    var expr = spread.expression;

    if (expr is MethodInvocation && expr.methodName.name == 'toList') {
      expr = expr.target!;
    }

    if (expr is! MethodInvocation) return;
    if (expr.methodName.name != 'map') return;

    final args = expr.argumentList.arguments;
    if (args.isEmpty) return;
    if (args.first is! FunctionExpression) return;

    rule.reportAtNode(spread);
  }
}
