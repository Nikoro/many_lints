import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// The combinators that make an `Option` worth its wrapper.
///
/// `toNullable` and `getOrElse` are deliberately absent: they *unwrap*. A
/// local that is wrapped and then immediately unwrapped is exactly the shape
/// this rule exists to find, so counting them as composition would make it
/// report nothing at all.
const _combinators = {
  'map',
  'flatMap',
  'andThen',
  'alt',
  'match',
  'fold',
  'toEither',
  'filter',
};

/// Warns when a local `Option` is created and unwrapped without ever being
/// composed.
///
/// `Option` earns its keep through its combinators: chaining with `flatMap`,
/// promoting absence to a failure with `toEither`, providing a fallback with
/// `alt`. A local that is wrapped and then immediately unwrapped gets none of
/// that, and pays for it — Dart's own nullable types have language support
/// (`?.`, `??`, narrowing after a null check) that `Option` cannot match.
///
/// fpdart's author says the same: `Option<T>` and `T?` are not mutually
/// exclusive, and the right move is to convert at the border rather than fight
/// the language.
///
/// This rule is deliberately opinionated and only belongs to the `pedantic`
/// preset, since a codebase that has standardised on `Option` everywhere is
/// making a coherent choice.
///
/// **Bad:**
/// ```dart
/// final option = Option.fromNullable(name);
/// final value = option.toNullable() ?? 'unknown';
/// ```
///
/// **Good:**
/// ```dart
/// final value = name ?? 'unknown';
/// ```
///
/// ## Options
///
/// - `ignore_public_api`: when `true` (the default), an `Option` in a public
///   signature is not reported — that is a contract, not a local convenience.
class AvoidUnnecessaryOption extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_option',
    "This 'Option' is never composed, so a nullable type would read better.",
    correctionMessage:
        "Use 'T?' and Dart's null-aware operators, or use one of Option's "
        'combinators to earn the wrapper.',
  );

  AvoidUnnecessaryOption()
    : super(
        name: 'avoid_unnecessary_option',
        description:
            'Warns when a local Option is wrapped and unwrapped without any '
            'combinator in between, where a nullable type reads better.',
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
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryOption rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    // Only locals: a field is part of a type's shape, and reporting it would
    // be a claim about the API rather than about this one expression.
    if (node.declaredFragment?.element is! LocalVariableElement) return;

    final initializer = node.initializer;
    if (initializer == null) return;

    final type = initializer.staticType;
    if (type == null) return;
    if (!optionChecker.isAssignableFromType(type)) return;

    if (rule.config.boolOption('ignore_public_api', defaultValue: true) &&
        _escapesToPublicApi(node)) {
      return;
    }

    final body = node.thisOrAncestorOfType<FunctionBody>();
    if (body == null) return;

    final name = node.name.lexeme;
    final usage = _CombinatorUsageFinder(name);
    body.accept(usage);

    // A variable that is never read at all is `unused_local_variable`'s
    // business, not this rule's.
    if (usage.reads == 0) return;
    if (usage.composed) return;

    rule.reportAtToken(node.name);
  }

  /// Whether the enclosing member is public, so its `Option` may be a contract.
  bool _escapesToPublicApi(AstNode node) {
    final method = node.thisOrAncestorOfType<MethodDeclaration>();
    if (method != null) return !method.name.lexeme.startsWith('_');

    final function = node.thisOrAncestorOfType<FunctionDeclaration>();
    if (function != null) return !function.name.lexeme.startsWith('_');

    return false;
  }
}

/// Counts reads of a variable and notes whether any of them composes.
class _CombinatorUsageFinder extends RecursiveAstVisitor<void> {
  final String name;
  int reads = 0;
  bool composed = false;

  _CombinatorUsageFinder(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != name) return;

    reads++;

    // `option.map(...)` and `option.flatMap(...)` reach here with the
    // identifier as the invocation's target.
    final parent = node.parent;
    if (parent is MethodInvocation && parent.realTarget == node) {
      if (_combinators.contains(parent.methodName.name)) composed = true;
      return;
    }

    // A bare read that is not a member access — passed to a function, returned,
    // matched with a pattern — keeps the Option as a value, which is a use the
    // wrapper is doing work for.
    if (parent is! PropertyAccess && parent is! PrefixedIdentifier) {
      composed = true;
    }
  }
}
