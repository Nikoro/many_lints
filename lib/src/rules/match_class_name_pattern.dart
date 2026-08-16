import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../rule_config.dart';

/// Warns when a class name does not match the configured pattern.
///
/// This is the general form of `use_class_prefix` and `use_class_suffix`: a
/// project that wants `PascalCase` and nothing else, or wants every class in
/// one folder to match `^[A-Z][A-Za-z]*Page$`, states it once as a regular
/// expression rather than as a list of affixes.
///
/// **This rule reports nothing until configured.** Set `pattern` to a regular
/// expression, which must match the whole name. Narrow it to a subtree with
/// the per-rule `include`:
///
/// ```yaml
/// rules:
///   match_class_name_pattern:
///     pattern: '[A-Z][A-Za-z0-9]*Page'
///     include: ['lib/**/presentation/**']
/// ```
///
/// An invalid pattern is ignored rather than throwing, like every other
/// malformed option: a plugin cannot report a diagnostic against a YAML file.
class MatchClassNamePattern extends ManyLintsRule {
  static const LintCode code = LintCode(
    'match_class_name_pattern',
    "The class name '{0}' does not match '{1}'.",
    correctionMessage: 'Rename it to match the configured pattern.',
  );

  MatchClassNamePattern()
    : super(
        name: 'match_class_name_pattern',
        description:
            'Warns when a class name does not match the configured pattern.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addMixinDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MatchClassNamePattern rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) =>
      _check(node.namePart.typeName);

  @override
  void visitMixinDeclaration(MixinDeclaration node) => _check(node.name);

  @override
  void visitEnumDeclaration(EnumDeclaration node) =>
      _check(node.namePart.typeName);

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) =>
      _check(node.namePart.typeName);

  void _check(Token token) {
    final pattern = rule.config.patternOption('pattern');
    if (pattern == null) return;

    final name = token.lexeme;
    if (pattern.matchesWholeValue(name)) return;

    rule.reportAtToken(token, arguments: [name, pattern.pattern]);
  }
}
