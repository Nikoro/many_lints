import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferExplicitParameterNames extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_explicit_parameter_names',
    'This function type declares unnamed parameters.',
    correctionMessage: 'Name them, so a caller knows what to pass.',
  );

  PreferExplicitParameterNames()
    : super(
        name: 'prefer_explicit_parameter_names',
        description: 'Warns when a function type declares unnamed parameters.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addGenericFunctionType(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferExplicitParameterNames rule;

  _Visitor(this.rule);

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    final minParameters = rule.config.intOption(
      'min_parameters',
      defaultValue: 2,
    );

    final parameters = node.parameters.parameters;
    if (parameters.length < minParameters) return;

    // Edge case: an unnamed parameter has an empty name token rather than a null one
    final unnamed = parameters.where((p) => p.name?.lexeme.isEmpty ?? true);
    if (unnamed.isEmpty) return;

    rule.reportAtNode(node.parameters);
  }
}
