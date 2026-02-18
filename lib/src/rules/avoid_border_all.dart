import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';

/// Warns when `Border.all()` is used instead of `Border.fromBorderSide()`.
///
/// `Border.all()` calls `Border.fromBorderSide()` under the hood, so using
/// `Border.fromBorderSide(BorderSide(...))` directly allows the expression
/// to be const.
class AvoidBorderAll extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_border_all',
    'Prefer Border.fromBorderSide over Border.all.',
    correctionMessage:
        'Replace with Border.fromBorderSide(BorderSide(...)) for const support.',
  );

  AvoidBorderAll()
    : super(
        name: 'avoid_border_all',
        description:
            'Warns when Border.all() is used instead of Border.fromBorderSide().',
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
  final AvoidBorderAll rule;

  _Visitor(this.rule);

  static const _borderChecker = TypeChecker.fromName(
    'Border',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Border.all<TypeArgs>(...) is parsed as InstanceCreationExpression
    final constructorName = node.constructorName;
    if (constructorName.name?.name != 'all') return;
    final staticType = node.staticType;
    if (staticType == null || !_borderChecker.isExactlyType(staticType)) return;

    rule.reportAtNode(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Border.all(...) without type args is parsed as MethodInvocation
    if (node.methodName.name != 'all') return;
    final target = node.target;
    if (target is! SimpleIdentifier) return;
    final staticType = node.staticType;
    if (staticType == null || !_borderChecker.isExactlyType(staticType)) return;

    rule.reportAtNode(node);
  }
}
