import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a top-level constant does not carry the configured prefix.
///
/// A top-level constant is in scope everywhere the library is imported, under
/// a name that competes with every local. `defaultTimeout` at the top level
/// reads identically to a local of the same name at the point of use, so a
/// prefix — `kDefaultTimeout`, Flutter's own convention — makes the origin
/// visible without a jump to the declaration.
///
/// **This rule reports nothing until configured**, since the prefix is a house
/// style with no defensible default. Set `prefix: k` to adopt Flutter's.
///
/// Only *public* top-level constants are checked: a private one cannot collide
/// outside its own library, which is the problem the prefix solves.
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
    // Silent until the project picks a prefix: there is no defensible default.
    final prefix = rule.config.options['prefix'];
    if (prefix is! String || prefix.isEmpty) return;

    if (!node.variables.isConst) return;

    for (final variable in node.variables.variables) {
      final name = variable.name.lexeme;
      // A private constant cannot collide outside its library, which is the
      // problem the prefix exists to solve.
      if (name.startsWith('_')) continue;
      if (name.startsWith(prefix)) continue;

      rule.reportAtToken(variable.name, arguments: [name, prefix]);
    }
  }
}
