import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when an Image widget is wrapped in an Opacity widget.
///
/// The Image widget has a dedicated `opacity` parameter that is more
/// efficient than wrapping the widget in an Opacity widget.
class AvoidIncorrectImageOpacity extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_incorrect_image_opacity',
    "Use Image's opacity parameter instead of wrapping it in an Opacity widget.",
    correctionMessage:
        'Pass opacity: AlwaysStoppedAnimation(value) to the Image widget.',
  );

  AvoidIncorrectImageOpacity()
    : super(
        name: 'avoid_incorrect_image_opacity',
        description:
            "Use Image's opacity parameter instead of wrapping it in Opacity.",
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
  final AvoidIncorrectImageOpacity rule;

  _Visitor(this.rule);

  static const _opacityChecker = TypeChecker.fromName(
    'Opacity',
    packageName: 'flutter',
  );

  static const _imageChecker = TypeChecker.fromName(
    'Image',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !_opacityChecker.isExactly(element)) return;

    _checkChildArgument(node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final type = node.staticType;
    if (type == null || !_opacityChecker.isExactlyType(type)) return;

    _checkChildArgument(node.argumentList, node.methodName);
  }

  void _checkChildArgument(ArgumentList argumentList, AstNode reportNode) {
    final child = namedArgumentValue(argumentList.arguments, 'child');
    if (child == null) return;

    final childType = child.staticType;
    if (childType != null && _imageChecker.isAssignableFromType(childType)) {
      rule.reportAtNode(reportNode);
    }
  }
}
