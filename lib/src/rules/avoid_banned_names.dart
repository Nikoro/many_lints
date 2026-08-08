import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';

/// Warns when a declaration uses a banned name.
///
/// Enforces a project's vocabulary: ban `data`, `temp`, `info` and `manager`
/// as meaningless, or reserve a term your domain uses for one specific thing.
/// Nothing is banned until you configure it.
///
/// Only *declarations* are checked — the place a name is chosen. Reporting
/// every reference too would bury the one line the author can act on under
/// diagnostics they cannot fix without renaming the declaration anyway.
///
/// **Configuration** (`many_lints.yaml`):
///
/// ```yaml
/// rules:
///   avoid_banned_names:
///     banned:
///       - deny: ['data', 'temp', 'info', 'manager']
///         message: 'Name it for what it holds.'
///       - deny_pattern: ['.*Impl']
///         message: 'Name the implementation for how it differs.'
/// ```
///
/// **BAD:**
/// ```dart
/// final data = fetchUsers();  // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// final users = fetchUsers();
/// ```
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
    // One callback per kind of declaration that names something. Registering
    // `addSimpleIdentifier` instead would also visit every *reference*, which
    // this rule deliberately leaves alone.
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

  /// Reports [name] when a configured entry bans it.
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
