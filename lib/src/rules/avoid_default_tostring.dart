import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidDefaultTostring extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_default_tostring',
    "'{0}' does not override toString.",
    correctionMessage:
        "This renders as \"Instance of '{0}'\". Override toString, or "
        'interpolate the specific fields you need.',
  );

  AvoidDefaultTostring()
    : super(
        name: 'avoid_default_tostring',
        description:
            'Warns when a value whose class does not override toString is '
            'interpolated into a string.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInterpolationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidDefaultTostring rule;

  _Visitor(this.rule);

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    final type = node.expression.staticType;
    if (type is! InterfaceType) return;

    final element = type.element;

    final isEnum = element is EnumElement;
    if (element is! ClassElement && !isEnum) return;
    if (element.library.isInSdk) return;

    if (isEnum &&
        !rule.config.boolOption('report_enums', defaultValue: false)) {
      return;
    }

    if (_hasToStringOverride(type)) return;

    rule.reportAtNode(node.expression, arguments: [element.name ?? '']);
  }

  bool _hasToStringOverride(InterfaceType type) {
    for (final method in type.methods) {
      if (method.name == 'toString') return true;
    }

    for (final supertype in type.allSupertypes) {
      if (supertype.isDartCoreObject) continue;
      for (final method in supertype.methods) {
        if (method.name == 'toString') return true;
      }
    }
    return false;
  }
}
