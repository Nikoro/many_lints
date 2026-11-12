import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferPrefixedGlobalConstants extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_prefixed_global_constants',
    "The global constant '{0}' does not start with '{1}'.",
    correctionMessage: 'Prefix it, so its origin is visible where it is used.',
  );

  PreferPrefixedGlobalConstants()
    : super(
        name: 'prefer_prefixed_global_constants',
        description:
            'Warns when a top-level constant does not carry the configured '
            'prefix.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addTopLevelVariableDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferPrefixedGlobalConstants rule;

  _Visitor(this.rule);

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    final prefix = rule.config.options['prefix'];
    if (prefix is! String || prefix.isEmpty) return;

    if (!node.variables.isConst) return;

    for (final variable in node.variables.variables) {
      final name = variable.name.lexeme;
      final cannotCollideOutsideLibrary = name.startsWith('_');
      if (cannotCollideOutsideLibrary) continue;
      if (name.startsWith(prefix)) continue;

      rule.reportAtToken(variable.name, arguments: [name, prefix]);
    }
  }
}
