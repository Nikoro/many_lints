import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `BorderRadius.circular()` is used instead of
/// `BorderRadius.all(Radius.circular())`.
///
/// `BorderRadius.circular` calls `BorderRadius.all(Radius.circular())` under
/// the hood. Using the explicit form allows the expression to be const.
class PreferConstBorderRadius extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_const_border_radius',
    'Prefer BorderRadius.all(Radius.circular()) over BorderRadius.circular().',
    correctionMessage:
        'Replace with const BorderRadius.all(Radius.circular(...)) for const support.',
  );

  PreferConstBorderRadius()
    : super(
        name: 'prefer_const_border_radius',
        description:
            'Warns when BorderRadius.circular() is used instead of BorderRadius.all(Radius.circular()).',
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
  final PreferConstBorderRadius rule;

  _Visitor(this.rule);

  static const _borderRadiusChecker = TypeChecker.fromName(
    'BorderRadius',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // BorderRadius.circular<TypeArgs>(...) is parsed as InstanceCreationExpression
    final constructorName = node.constructorName;
    if (constructorName.name?.name != 'circular') return;
    final staticType = node.staticType;
    if (staticType == null || !_borderRadiusChecker.isExactlyType(staticType)) {
      return;
    }

    rule.reportAtNode(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // BorderRadius.circular(...) without type args is parsed as MethodInvocation
    if (node.methodName.name != 'circular') return;
    final target = node.target;
    if (target is! SimpleIdentifier) return;
    final staticType = node.staticType;
    if (staticType == null || !_borderRadiusChecker.isExactlyType(staticType)) {
      return;
    }

    rule.reportAtNode(node);
  }
}
