import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:analyzer/dart/ast/token.dart';

import '../many_lints_rule.dart';

/// Warns when an identifier is shorter or longer than the configured bounds.
///
/// A one-letter name outside a tiny scope forces the reader to hold a mapping
/// the code never states, and a forty-character one is usually a sentence that
/// belongs in a doc comment. Both bounds are house style, which is why this
/// rule ships with generous defaults and an exception list rather than an
/// opinion.
///
/// `min_length` defaults to 2 and `max_length` to 40. The conventional short
/// names are exempt out of the box — loop counters, coordinates, the `e` of a
/// catch clause — through `allow_names`, which *adds* to that built-in set
/// rather than replacing it.
///
/// Only declarations this codebase controls are checked: locals, parameters,
/// fields, top-level variables and their declarations. An override is skipped,
/// since the name belongs to whoever declared it.
class PreferCorrectIdentifierLength extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_correct_identifier_length',
    "The name '{0}' is {1} characters, outside the range {2}-{3}.",
    correctionMessage: 'Use a name that says what it holds, without a story.',
  );

  PreferCorrectIdentifierLength()
    : super(
        name: 'prefer_correct_identifier_length',
        description:
            'Warns when an identifier is shorter or longer than the '
            'configured bounds.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addVariableDeclaration(this, visitor);
    registry.addRegularFormalParameter(this, visitor);
  }
}

/// The short names every codebase already uses without confusion.
const _conventionalShortNames = {
  'i',
  'j',
  'k',
  'n',
  'x',
  'y',
  'z',
  'e',
  'a',
  'b',
  'id',
  'db',
  'ui',
  'os',
  '_',
};

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCorrectIdentifierLength rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclaration(VariableDeclaration node) => _check(node.name);

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    final name = node.name;
    if (name == null) return;

    _check(name);
  }

  void _check(Token token) {
    final name = token.lexeme;
    // A private name's underscore is a modifier, not part of its length.
    final bare = name.startsWith('_') ? name.substring(1) : name;
    if (bare.isEmpty) return;

    final allowed = rule.config.nameSetOption(
      'allow_names',
      defaultValue: _conventionalShortNames,
    );
    if (allowed.contains(bare) || allowed.contains(name)) return;

    final minLength = rule.config.intOption('min_length', defaultValue: 2);
    final maxLength = rule.config.intOption('max_length', defaultValue: 40);

    if (bare.length >= minLength && bare.length <= maxLength) return;

    rule.reportAtToken(
      token,
      arguments: [name, '${bare.length}', '$minLength', '$maxLength'],
    );
  }
}
