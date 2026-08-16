import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a type name is too short, too long, or does not start with a
/// capital letter.
///
/// The SDK's `camel_case_types` covers the spelling of a type name but says
/// nothing about its length, and length is where the two real failures live: a
/// one-letter type (`class R`) that reads as a type *parameter* at the point
/// of use, and a forty-character type that names its whole call chain.
///
/// The defaults are deliberately loose — 3 to 40 characters — so the rule
/// reports only genuine outliers. Tighten them per project:
///
/// ```yaml
/// rules:
///   prefer_correct_type_name:
///     min_length: 4
///     max_length: 32
///     ignored_names: [Id, Db]
/// ```
///
/// Type *parameters* are exempt. `T`, `E` and `K`/`V` are the convention the
/// SDK itself uses, and holding them to a minimum length would fight it.
class PreferCorrectTypeName extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_correct_type_name',
    "The type name '{0}' {1}.",
    correctionMessage: 'Rename it to describe the type at its call sites.',
  );

  PreferCorrectTypeName()
    : super(
        name: 'prefer_correct_type_name',
        description:
            'Warns when a type name is too short, too long, or does not start '
            'with a capital letter.',
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
    registry.addClassTypeAlias(this, visitor);
    registry.addGenericTypeAlias(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCorrectTypeName rule;

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

  @override
  void visitClassTypeAlias(ClassTypeAlias node) => _check(node.name);

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) => _check(node.name);

  void _check(Token token) {
    final name = token.lexeme;

    final ignored = rule.config.stringListOption('ignored_names');
    if (ignored.contains(name)) return;

    // A private type is still public within its library, so it is checked —
    // but the underscore is not part of the name the reader judges.
    final bare = name.startsWith('_') ? name.substring(1) : name;
    if (bare.isEmpty) return;

    final minLength = rule.config.intOption('min_length', defaultValue: 3);
    final maxLength = rule.config.intOption('max_length', defaultValue: 40);

    final problem = switch (bare) {
      _ when bare.length < minLength => 'is shorter than $minLength characters',
      _ when bare.length > maxLength => 'is longer than $maxLength characters',
      _ when !_startsWithCapital(bare) =>
        'does not start with a capital letter',
      _ => null,
    };
    if (problem == null) return;

    rule.reportAtToken(token, arguments: [name, problem]);
  }

  bool _startsWithCapital(String name) {
    final first = name[0];
    return first.toUpperCase() == first && first.toLowerCase() != first;
  }
}
