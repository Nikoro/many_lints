import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';

class AvoidBannedNames extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_banned_names',
    "The name '{0}' is banned.{1}",
    correctionMessage: 'Rename this declaration to something more specific.',
  );

  AvoidBannedNames()
    : super(
        name: 'avoid_banned_names',
        description: 'Warns when a declaration uses a banned name.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    // Edge case: declarations only: addSimpleIdentifier would also visit references, which stay allowed
    registry.addVariableDeclaration(this, visitor);
    registry.addRegularFormalParameter(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addClassDeclaration(this, visitor);
    registry.addMixinDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
    registry.addTypeParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBannedNames rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclaration(VariableDeclaration node) => _check(node.name);

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) =>
      _check(node.name);

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _check(node.name);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) => _check(node.name);

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
  void visitTypeParameter(TypeParameter node) => _check(node.name);

  void _check(Token? name) {
    if (name == null) return;

    final entries = readBannedEntries(rule.config);
    if (entries.isEmpty) return;

    final identifier = name.lexeme;
    if (identifier.isEmpty) return;

    final banned = findBannedEntry(
      entries: entries,
      value: identifier,
      relativePath: rule.relativePath,
    );
    if (banned == null) return;

    rule.reportAtSourceRange(
      SourceRange(name.offset, name.length),
      arguments: [identifier, messageSuffix(banned)],
    );
  }
}
