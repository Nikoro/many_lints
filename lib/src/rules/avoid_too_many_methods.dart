import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a class declares more methods than the configured budget.
///
/// Method count is the cheapest measure of whether a class still has one
/// responsibility. A class with thirty methods is usually two or three classes
/// that never got separated, and the tell is that its name has to be vague
/// enough to cover all of them.
///
/// The limit is `max_methods`, defaulting to 20. Getters, setters and
/// operators are not counted by default: they are the class's *surface*, not
/// its behaviour, and a data class with fifteen getters is not the problem
/// this rule exists for. Set `count_accessors: true` to include them.
///
/// Constructors are never counted — a class with several named constructors is
/// offering ways to build one thing, not doing several things.
class AvoidTooManyMethods extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_too_many_methods',
    "'{0}' declares {1} methods, over the limit of {2}.",
    correctionMessage:
        'Split out the group of methods that shares a subject, or raise '
        'max_methods.',
  );

  AvoidTooManyMethods()
    : super(
        name: 'avoid_too_many_methods',
        description:
            'Warns when a class declares more methods than the configured '
            'budget.',
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
    registry.addExtensionDeclaration(this, visitor);
  }
}

/// Enough for a class doing one thing thoroughly.
const _defaultMaxMethods = 20;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidTooManyMethods rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) =>
      _check(node.body, node.namePart.typeName);

  @override
  void visitMixinDeclaration(MixinDeclaration node) =>
      _check(node.body, node.name);

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    // An unnamed extension has no token to point at, and its members are
    // scoped to the type it extends rather than to a name a reader can act on.
    final name = node.name;
    if (name == null) return;

    _check(node.body, name);
  }

  void _check(AstNode body, Token nameToken) {
    if (body is! BlockClassBody) return;

    final maxMethods = rule.config.intOption(
      'max_methods',
      defaultValue: _defaultMaxMethods,
    );
    final countAccessors = rule.config.boolOption(
      'count_accessors',
      defaultValue: false,
    );

    final methods = body.members.whereType<MethodDeclaration>().where(
      (member) =>
          countAccessors ||
          !member.isGetter && !member.isSetter && !member.isOperator,
    );

    final count = methods.length;
    if (count <= maxMethods) return;

    rule.reportAtToken(
      nameToken,
      arguments: [nameToken.lexeme, '$count', '$maxMethods'],
    );
  }
}
