import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferCorrectJsonCasts extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_correct_json_casts',
    "Casting a JSON value to non-nullable '{0}' throws when the key is "
        'missing.',
    correctionMessage:
        "Cast to '{0}?' and supply a fallback with '??', so a missing key "
        'fails where you can see it.',
  );

  PreferCorrectJsonCasts()
    : super(
        name: 'prefer_correct_json_casts',
        description:
            'Warns when a value indexed out of a JSON map is cast to a '
            'non-nullable type, which throws on a missing key.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addAsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCorrectJsonCasts rule;

  _Visitor(this.rule);

  @override
  void visitAsExpression(AsExpression node) {
    final expression = node.expression;
    if (expression is! IndexExpression) return;

    final targetType = expression.realTarget.staticType;
    if (targetType is! InterfaceType) return;
    if (!targetType.isDartCoreMap) return;

    // Edge case: a precisely typed map cannot yield null for a present key
    final valueType = targetType.typeArguments.elementAtOrNull(1);
    if (valueType is! DynamicType) return;

    final castType = node.type.type;
    if (castType == null) return;

    if (castType.nullabilitySuffix == NullabilitySuffix.question) return;

    if (castType is DynamicType || castType.isDartCoreObject) return;

    rule.reportAtNode(node, arguments: [castType.getDisplayString()]);
  }
}
