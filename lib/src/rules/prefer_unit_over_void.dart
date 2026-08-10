import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when an fpdart type is parameterised with `void` instead of `Unit`.
///
/// `void` is not a value in Dart: you cannot pass it, store it, or feed it to
/// the next step of a pipeline. A `TaskEither<Failure, void>` therefore stops
/// composing — `flatMap` on it has nothing meaningful to bind, and callers end
/// up unwrapping to `null` and re-deriving success from that.
///
/// `Unit` is fpdart's answer: a real type with exactly one value, which says
/// "succeeded, with nothing to report" while staying chainable.
///
/// **Bad:**
/// ```dart
/// TaskEither<Failure, void> save(User user) => ...;
/// ```
///
/// **Good:**
/// ```dart
/// TaskEither<Failure, Unit> save(User user) => ...;
/// ```
///
/// ## Options
///
/// - `ignore_overrides`: when `true` (the default), a member marked
///   `@override` is not reported — its signature is fixed by the supertype, so
///   the fix belongs there instead.
class PreferUnitOverVoid extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_unit_over_void',
    "Use 'Unit' rather than 'void' as an fpdart type argument.",
    correctionMessage:
        "Replace 'void' with 'Unit' so the value stays composable in a "
        'pipeline.',
  );

  PreferUnitOverVoid()
    : super(
        name: 'prefer_unit_over_void',
        description:
            'Warns when an fpdart type is parameterised with void, which does '
            'not compose, instead of Unit.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferUnitOverVoid rule;

  _Visitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.isEmpty) return;

    final type = node.type;
    if (type == null) return;
    if (!anyFpdartChecker.isAssignableFromType(type)) return;

    if (rule.config.boolOption('ignore_overrides', defaultValue: true) &&
        _isInOverride(node)) {
      return;
    }

    for (final argument in typeArguments) {
      if (argument is! NamedType) continue;
      if (argument.type is! VoidType) continue;

      rule.reportAtNode(argument);
    }
  }

  /// Whether [node] sits in the signature of an `@override` member.
  bool _isInOverride(AstNode node) {
    final method = enclosingOfType<MethodDeclaration>(node);
    return method != null && hasOverrideAnnotation(method);
  }
}
