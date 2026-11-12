import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ast_node_analysis.dart';
import '../flutter_type_checkers.dart';

class PreferSizedBoxSquare extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_sized_box_square',
    'Use SizedBox.square instead of SizedBox with equal width and height.',
    correctionMessage: 'Try using SizedBox.square(dimension: ...) instead.',
  );

  PreferSizedBoxSquare()
    : super(
        name: 'prefer_sized_box_square',
        description:
            'Prefer SizedBox.square when width and height are identical.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSizedBoxSquare rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.name != null) return;
    _check(node.staticType, node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final type = node.staticType;
    if (type == null || !sizedBoxChecker.isExactlyType(type)) return;
    // Edge case: a target here means a named constructor such as `SizedBox.square`.
    if (node.target != null) return;
    _check(type, node.argumentList, node.methodName);
  }

  void _check(
    DartType? staticType,
    ArgumentList argumentList,
    AstNode reportNode,
  ) {
    if (staticType == null) return;
    if (!sizedBoxChecker.isExactlyType(staticType)) return;

    final args = argumentList.arguments;

    final widthArg = namedArgumentValue(args, 'width');
    final heightArg = namedArgumentValue(args, 'height');

    if (widthArg == null || heightArg == null) return;

    if (widthArg.toSource() == heightArg.toSource()) {
      rule.reportAtNode(reportNode);
    }
  }
}
