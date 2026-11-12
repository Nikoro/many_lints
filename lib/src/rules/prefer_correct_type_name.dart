import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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
