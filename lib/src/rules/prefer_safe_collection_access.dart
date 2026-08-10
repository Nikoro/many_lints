import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

/// The throwing accessors fpdart ships a total counterpart for.
const _accessorReplacements = {
  'first': 'head',
  'last': 'lastOption',
  'single': 'singleOption',
};

/// Warns when a throwing collection accessor is used where fpdart offers a
/// total one.
///
/// `list.first` throws on an empty list; `list.head` returns `None`. In an
/// fpdart pipeline that difference matters twice over: the throw escapes the
/// error channel the pipeline exists to carry, so a `StateError` surfaces past
/// every `fold` the caller wrote.
///
/// By default only expressions *inside* an fpdart pipeline are reported —
/// where the total accessor composes and the throw is genuinely out of place.
/// Set `report_outside_pipelines: true` to apply the same rule to the whole
/// file.
///
/// **Bad:**
/// ```dart
/// TaskEither<Failure, Player> firstPlayer(List<Player> players) =>
///     TaskEither.of(players.first);
/// ```
///
/// **Good:**
/// ```dart
/// TaskEither<Failure, Player> firstPlayer(List<Player> players) =>
///     players.head.toEither(() => const NoPlayersFailure()).toTaskEither();
/// ```
///
/// ## Options
///
/// - `report_outside_pipelines`: when `true`, report every throwing accessor
///   in the file rather than only those inside an fpdart pipeline. Defaults to
///   `false`.
/// - `accessors` / `additional_accessors`: replace or extend the set of
///   accessor names that are checked.
class PreferSafeCollectionAccess extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_safe_collection_access',
    "Use '{0}' instead of '{1}', which throws when there is no element.",
    correctionMessage:
        "The total accessor returns an 'Option', so absence stays in the "
        'value instead of escaping as an exception.',
  );

  PreferSafeCollectionAccess()
    : super(
        name: 'prefer_safe_collection_access',
        description:
            'Warns when a throwing collection accessor is used in an fpdart '
            'pipeline, where absence should be a value rather than an '
            'exception.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPropertyAccess(this, visitor);
    registry.addPrefixedIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSafeCollectionAccess rule;

  _Visitor(this.rule);

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

  /// `list.first` where `list` is a simple identifier parses as a
  /// [PrefixedIdentifier].
  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _check(node, node.identifier, node.prefix.staticType);
  }

  /// Any richer receiver — `a.b.first`, `f().first` — parses as a
  /// [PropertyAccess].
  @override
  void visitPropertyAccess(PropertyAccess node) {
    _check(node, node.propertyName, node.realTarget.staticType);
  }

  void _check(Expression node, SimpleIdentifier property, DartType? type) {
    if (type == null) return;
    if (!_iterableChecker.isAssignableFromType(type)) return;

    final accessors = rule.config.nameSetOption(
      'accessors',
      defaultValue: _accessorReplacements.keys.toSet(),
    );
    final name = property.name;
    if (!accessors.contains(name)) return;

    if (!rule.config.boolOption(
          'report_outside_pipelines',
          defaultValue: false,
        ) &&
        !_isInsideFpdartPipeline(node)) {
      return;
    }

    rule.reportAtNode(
      property,
      arguments: [_accessorReplacements[name] ?? '${name}Option', name],
    );
  }

  /// Whether [node] sits somewhere an fpdart value is being built.
  ///
  /// Deliberately generous: anywhere the enclosing member's return type or an
  /// enclosing expression is an fpdart type counts. A narrower test would miss
  /// the common case of a helper whose result feeds a pipeline one call away,
  /// and the cost of being generous is only that the rule fires slightly more
  /// often inside code that is already fpdart-shaped.
  bool _isInsideFpdartPipeline(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is Expression) {
        final type = current.staticType;
        if (type != null && anyFpdartChecker.isAssignableFromType(type)) {
          return true;
        }
      }

      final returnType = switch (current) {
        MethodDeclaration(:final returnType) => returnType?.type,
        FunctionDeclaration(:final returnType) => returnType?.type,
        _ => null,
      };
      if (returnType != null &&
          anyFpdartChecker.isAssignableFromType(returnType)) {
        return true;
      }
    }

    return false;
  }
}
