import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when `getOrElse` on a failable type discards the failure.
///
/// `Either.getOrElse` hands its callback the `Left` value. A callback that
/// ignores that parameter throws the failure away: the pipeline carried the
/// reason all the way to the boundary, and the boundary drops it in favour of
/// a default the caller cannot distinguish from a real result.
///
/// Sometimes that is exactly right — a cached value, a display fallback. But
/// it is a decision, and written as `(_) => 0` it does not look like one. Using
/// the parameter, or folding with `match`, makes the choice visible.
///
/// `Option.getOrElse` takes no parameter and is never reported: there is no
/// failure there to discard.
///
/// **Bad:**
/// ```dart
/// final count = result.getOrElse((_) => 0);
/// ```
///
/// **Good:**
/// ```dart
/// final count = result.match((failure) {
///   log(failure);
///   return 0;
/// }, (value) => value);
/// ```
///
/// ## Options
///
/// - `ignore_tests`: when `true` (the default), files under `test/` are not
///   reported — discarding a failure in a fixture is ordinary.
class AvoidGetOrElseSwallowingFailure extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_get_or_else_swallowing_failure',
    "This 'getOrElse' discards the failure it was given.",
    correctionMessage:
        'Use the failure parameter, or fold with match, so dropping it is a '
        'visible decision.',
  );

  AvoidGetOrElseSwallowingFailure()
    : super(
        name: 'avoid_get_or_else_swallowing_failure',
        description:
            'Warns when getOrElse on Either or TaskEither ignores the failure '
            'parameter, discarding the reason the pipeline carried.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidGetOrElseSwallowingFailure rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'getOrElse') return;

    if (rule.config.boolOption('ignore_tests', defaultValue: true) &&
        (rule.relativePath?.startsWith('test/') ?? false)) {
      return;
    }

    // Only the failable wrappers: `Option.getOrElse` takes no parameter, so
    // there is nothing to discard.
    final targetType = node.realTarget?.staticType;
    if (targetType == null) return;
    if (!failableFpdartChecker.isAssignableFromType(targetType)) return;

    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return;

    final callback = arguments.first.argumentExpression;
    if (callback is! FunctionExpression) return;

    final parameters = callback.parameters?.parameters;
    if (parameters == null || parameters.isEmpty) return;

    final parameter = parameters.first;
    final name = parameter.name?.lexeme;
    if (name == null) return;

    // A wildcard says outright that the failure is unused; any other name has
    // to be checked against the body, since naming it and then ignoring it is
    // the same discard.
    if (!_isWildcard(name) && _isReferencedIn(callback.body, name)) return;

    rule.reportAtNode(node.methodName);
  }

  /// Whether [name] is a discard (`_`, `__`, ...).
  bool _isWildcard(String name) => RegExp(r'^_+$').hasMatch(name);

  /// Whether [name] is read anywhere in [body].
  bool _isReferencedIn(FunctionBody body, String name) {
    final finder = _IdentifierFinder(name);
    body.accept(finder);
    return finder.found;
  }
}

/// Looks for a reference to a given name.
class _IdentifierFinder extends RecursiveAstVisitor<void> {
  final String name;
  bool found = false;

  _IdentifierFinder(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) found = true;
  }
}
