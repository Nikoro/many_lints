import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

class PreferDoNotation extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_do_notation',
    "These '{0}' nested 'flatMap' callbacks would read flatter as a 'Do' "
        'block.',
    correctionMessage:
        "Use '<Type>.Do((\$) { ... })' and extract each step with '\$', which "
        'has the same short-circuiting but no nesting.',
  );

  PreferDoNotation()
    : super(
        name: 'prefer_do_notation',
        description:
            'Warns when flatMap callbacks nest deeply enough that Do notation '
            'would read better, with identical semantics.',
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
  final PreferDoNotation rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isFpdartFlatMap(node)) return;

    // Edge case: the nest is one shape with one fix, so inner calls stay silent
    if (_enclosingFlatMapCallback(node) != null) return;

    final depth = _nestingDepth(node);
    final maxDepth = rule.config.options.containsKey('max_flat_map_depth')
        ? rule.config.intOption('max_flat_map_depth', defaultValue: 3)
        : rule.config.intOption('max_flatmap_depth', defaultValue: 3);
    if (depth < maxDepth) {
      return;
    }

    rule.reportAtNode(node.methodName, arguments: ['$depth']);
  }

  bool _isFpdartFlatMap(MethodInvocation node) {
    if (node.methodName.name != 'flatMap') return false;

    final targetType = node.realTarget?.staticType;
    return targetType != null &&
        anyFpdartChecker.isAssignableFromType(targetType);
  }

  MethodInvocation? _enclosingFlatMapCallback(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is! FunctionExpression) continue;

      final parent = current.parent;
      if (parent is! ArgumentList) continue;

      final invocation = parent.parent;
      if (invocation is MethodInvocation && _isFpdartFlatMap(invocation)) {
        return invocation;
      }
    }

    return null;
  }

  int _nestingDepth(MethodInvocation node) {
    var depth = 1;

    for (final argument in node.argumentList.arguments) {
      final callback = argument.argumentExpression;
      if (callback is! FunctionExpression) continue;

      final inner = _deepestFlatMapIn(callback.body);
      if (inner != null) depth += _nestingDepth(inner);
    }

    return depth;
  }

  MethodInvocation? _deepestFlatMapIn(FunctionBody body) {
    final finder = _NestedFlatMapFinder(_isFpdartFlatMap);
    body.accept(finder);
    return finder.found;
  }
}

class _NestedFlatMapFinder extends RecursiveAstVisitor<void> {
  final bool Function(MethodInvocation) isFlatMap;
  MethodInvocation? found;

  _NestedFlatMapFinder(this.isFlatMap);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (found != null) return;
    if (isFlatMap(node)) {
      found = node;
      return;
    }
    super.visitMethodInvocation(node);
  }
}
