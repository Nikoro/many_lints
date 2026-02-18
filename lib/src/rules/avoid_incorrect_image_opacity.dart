import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';

/// Warns when an Image widget is wrapped in an Opacity widget.
///
/// The Image widget has a dedicated `opacity` parameter that is more
/// efficient than wrapping the widget in an Opacity widget.
class AvoidIncorrectImageOpacity extends AnalysisRule {
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
    for (final arg in argumentList.arguments.whereType<NamedExpression>()) {
      if (arg.name.label.name == 'child') {
        final childType = arg.expression.staticType;
        if (childType != null &&
            _imageChecker.isAssignableFromType(childType)) {
          rule.reportAtNode(reportNode);
        }
        return;
      }
    }
  }
}
