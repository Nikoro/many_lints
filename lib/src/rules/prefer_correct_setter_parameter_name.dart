import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a setter's parameter is not named consistently.
///
/// A setter has exactly one parameter and its name appears nowhere but the
/// body, so the only thing it communicates is which convention the file
/// follows. When half the setters say `value` and half say `newValue` or `v`,
/// a reader scanning a class of setters has to look at each one to be sure
/// nothing else is going on.
///
/// The expected name is `value` by default, configurable through
/// `parameter_name`. `allow_names` accepts additional spellings without
/// replacing the default.
class PreferCorrectSetterParameterName extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_correct_setter_parameter_name',
    "The setter parameter '{0}' should be named '{1}'.",
    correctionMessage: 'Use the same parameter name in every setter.',
  );

  PreferCorrectSetterParameterName()
    : super(
        name: 'prefer_correct_setter_parameter_name',
        description:
            "Warns when a setter's parameter does not use the configured "
            'name.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCorrectSetterParameterName rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isSetter) return;
    // An override inherits its parameter name along with the signature.
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    final parameters = node.parameters?.parameters;
    if (parameters == null || parameters.length != 1) return;

    final token = parameters.single.name;
    if (token == null) return;

    final expected = rule.config.stringOption(
      'parameter_name',
      defaultValue: 'value',
    );
    final allowed = {expected, ...rule.config.stringListOption('allow_names')};
    if (allowed.contains(token.lexeme)) return;

    rule.reportAtToken(token, arguments: [token.lexeme, expected]);
  }
}
