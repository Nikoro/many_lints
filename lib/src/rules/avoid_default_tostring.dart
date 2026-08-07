import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a value with no `toString` override is interpolated.
///
/// `Object.toString` returns `Instance of 'Foo'`, which tells you the type
/// and nothing else. Logs and error messages built this way lose exactly
/// the information they were written to capture.
class AvoidDefaultTostring extends AnalysisRule {
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
  void registerNodeProcessors(
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

    // Only classes declared in the analysed code are worth reporting;
    // an SDK or package type without toString is not the user's to fix.
    if (element is! ClassElement) return;
    if (element.library.isInSdk) return;

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
