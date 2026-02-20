import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a `ListView` uses `shrinkWrap: true`.
///
/// Using `shrinkWrap` in lists is expensive performance-wise because the
/// list must be fully laid out to determine its size. Prefer using slivers
/// via `CustomScrollView` with `SliverList` for better performance.
class AvoidShrinkWrapInLists extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_shrink_wrap_in_lists',
    'Avoid using shrinkWrap in ListView.',
    correctionMessage:
        'Consider using CustomScrollView with SliverList instead.',
  );

  AvoidShrinkWrapInLists()
    : super(
        name: 'avoid_shrink_wrap_in_lists',
        description:
            'Warns when a ListView uses shrinkWrap: true, which is expensive performance-wise.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidShrinkWrapInLists rule;

  _Visitor(this.rule);

  static const _listViewChecker = TypeChecker.fromName(
    'ListView',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node.staticType, node.argumentList, node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node.staticType, node.argumentList, node);
  }

  void _check(
    DartType? staticType,
    ArgumentList argumentList,
    Expression node,
  ) {
    if (staticType == null || !_listViewChecker.isExactlyType(staticType)) {
      return;
    }

    for (final arg in argumentList.arguments.whereType<NamedExpression>()) {
      if (arg.name.label.name == 'shrinkWrap') {
        if (arg.expression case BooleanLiteral(value: true)) {
          rule.reportAtNode(arg);
          return;
        }
      }
    }
  }
}
