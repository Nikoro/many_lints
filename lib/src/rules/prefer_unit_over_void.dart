import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

class PreferUnitOverVoid extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_unit_over_void',
    "Use 'Unit' rather than 'void' as an fpdart type argument.",
    correctionMessage:
        "Replace 'void' with 'Unit' so the value stays composable in a "
        'pipeline.',
  );

  PreferUnitOverVoid()
    : super(
        name: 'prefer_unit_over_void',
        description:
            'Warns when an fpdart type is parameterised with void, which does '
            'not compose, instead of Unit.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferUnitOverVoid rule;

  _Visitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.isEmpty) return;

    final type = node.type;
    if (type == null) return;
    if (!anyFpdartChecker.isAssignableFromType(type)) return;

    if (rule.config.boolOption('ignore_overrides', defaultValue: true) &&
        _isInOverride(node)) {
      return;
    }

    for (final argument in typeArguments) {
      if (argument is! NamedType) continue;
      if (argument.type is! VoidType) continue;

      rule.reportAtNode(argument);
    }
  }

  bool _isInOverride(AstNode node) {
    final method = enclosingOfType<MethodDeclaration>(node);
    return method != null && hasOverrideAnnotation(method);
  }
}
