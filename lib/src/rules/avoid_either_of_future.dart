import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

/// The synchronous wrappers that cannot carry async work.
const _syncCheckers = TypeChecker.any([eitherChecker, optionChecker]);

/// Warns when a `Future` is nested inside a synchronous fpdart wrapper.
///
/// `Either` and `Option` are synchronous. Mapping one with an async function
/// produces `Either<L, Future<R>>`: the future is created and starts running,
/// but the error channel no longer covers it, so a rejection becomes an
/// unhandled async error instead of a `Left`. Callers then get a `Right`
/// holding a future that may already have failed.
///
/// The pipeline has to enter the async world at that point, which is what
/// `toTaskEither()` is for.
///
/// **Bad:**
/// ```dart
/// Either<Failure, Future<League>> save(LeagueDraft draft) =>
///     validate(draft).map((valid) => api.saveLeague(valid));
/// ```
///
/// **Good:**
/// ```dart
/// TaskEither<Failure, League> save(LeagueDraft draft) =>
///     validate(draft).toTaskEither().flatMap(
///           (valid) => TaskEither.tryCatch(
///             () => api.saveLeague(valid),
///             (e, s) => Failure.from(e),
///           ),
///         );
/// ```
class AvoidEitherOfFuture extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_either_of_future',
    "Avoid nesting a 'Future' inside '{0}'.",
    correctionMessage:
        "Convert to the async world with 'toTaskEither()' (or "
        "'toTaskOption()') and keep chaining there, so failures stay in the "
        'error channel.',
  );

  AvoidEitherOfFuture()
    : super(
        name: 'avoid_either_of_future',
        description:
            'Warns when a Future is nested inside the synchronous Either or '
            'Option, where the error channel no longer covers it.',
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
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidEitherOfFuture rule;

  _Visitor(this.rule);

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  /// Reports a written type such as `Either<Failure, Future<League>>`.
  @override
  void visitNamedType(NamedType node) {
    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.isEmpty) return;

    final type = node.type;
    if (type == null) return;
    if (!_syncCheckers.isAssignableFromType(type)) return;

    // The success channel is the last type argument for both wrappers:
    // `Either<L, R>` and `Option<T>`.
    final valueType = typeArguments.last;
    final resolved = valueType.type;
    if (resolved == null) return;
    if (!_futureChecker.isAssignableFromType(resolved)) return;

    rule.reportAtNode(valueType, arguments: [_wrapperName(type)]);
  }

  /// Reports a `map` whose callback returns a `Future`, which produces the
  /// same nesting without it ever being written down.
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'map') return;

    final targetType = node.realTarget?.staticType;
    if (targetType == null) return;
    if (!_syncCheckers.isAssignableFromType(targetType)) return;

    final resultType = node.staticType;
    if (resultType is! InterfaceType) return;

    final typeArguments = resultType.typeArguments;
    if (typeArguments.isEmpty) return;
    if (!_futureChecker.isAssignableFromType(typeArguments.last)) return;

    rule.reportAtNode(node.methodName, arguments: [_wrapperName(targetType)]);
  }

  /// The wrapper's display name, for the diagnostic message.
  String _wrapperName(DartType type) =>
      type is InterfaceType ? type.element.name ?? 'Either' : 'Either';
}
