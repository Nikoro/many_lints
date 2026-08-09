import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a value with no `toString` override is interpolated.
///
/// `Object.toString` returns `Instance of 'Foo'`, which tells you the type
/// and nothing else. Logs and error messages built this way lose exactly
/// the information they were written to capture.
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

    // Only classes and enums are considered; a mixin or extension type
    // reached here is not a value being interpolated in the sense this rule
    // means. An SDK or package type is not the user's to fix either.
    final isEnum = element is EnumElement;
    if (element is! ClassElement && !isEnum) return;
    if (element.library.isInSdk) return;

    // Enums render as `Status.active` by default — informative enough that
    // they stay exempt unless a project opts in. The option widens the rule,
    // so the default reproduces the previous behaviour exactly.
    if (isEnum &&
        !rule.config.boolOption('report_enums', defaultValue: false)) {
      return;
    }

    // Enums, records and the like render usefully by default.
    if (_hasToStringOverride(type)) return;

    rule.reportAtNode(node.expression, arguments: [element.name ?? '']);
  }

  /// Whether [type] or any supertype below `Object` overrides `toString`.
  bool _hasToStringOverride(InterfaceType type) {
    for (final method in type.methods) {
      if (method.name == 'toString') return true;
    }

    for (final supertype in type.allSupertypes) {
      // `Object` itself is the default we are warning about.
      if (supertype.isDartCoreObject) continue;
      for (final method in supertype.methods) {
        if (method.name == 'toString') return true;
      }
    }
    return false;
  }
}
