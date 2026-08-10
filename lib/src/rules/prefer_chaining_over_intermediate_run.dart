import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when a function body runs several fpdart pipelines separately instead
/// of chaining them.
///
/// `flatMap` carries the error channel through the whole pipeline: any step
/// that fails short-circuits the rest, and the failure handling is written
/// once, at the fold. Running each step with its own `.run()` throws that away
/// — every intermediate result has to be unwrapped by hand, each failure
/// branch rebuilt, and one forgotten `if` silently continues with a value that
/// was never produced.
///
/// That imperative shape is the exact thing `TaskEither` exists to delete; a
/// body with several `.run()` calls is usually a chain that was never joined
/// up.
///
/// **Bad:**
/// ```dart
/// Future<Either<Failure, Deal>> best() async {
///   final area = await getArea().run();
///   if (area case Right(value: final a)) {
///     return getRestaurant(a.id).run();
///   }
///   return Left(const AreaFailure());
/// }
/// ```
///
/// **Good:**
/// ```dart
/// TaskEither<Failure, Deal> best() =>
///     getArea().flatMap((a) => getRestaurant(a.id));
/// ```
///
/// ## Options
///
/// - `min_sequence`: how many `.run()` calls a body may contain before it is
///   reported. Defaults to `2` — one is a boundary, two is a chain.
class PreferChainingOverIntermediateRun extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_chaining_over_intermediate_run',
    "This body runs {0} fpdart pipelines separately.",
    correctionMessage:
        "Chain them with 'flatMap' and run once at the boundary, so a failure "
        'short-circuits the rest instead of being unwrapped by hand.',
  );

  PreferChainingOverIntermediateRun()
    : super(
        name: 'prefer_chaining_over_intermediate_run',
        description:
            'Warns when a function body calls run() on several fpdart '
            'pipelines instead of chaining them and running once.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferChainingOverIntermediateRun rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _check(node.body, node.name);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.body, node.name);

  void _check(FunctionBody body, Token name) {
    final collector = _RunCallCollector();
    body.accept(collector);

    final minSequence = rule.config.intOption('min_sequence', defaultValue: 2);
    if (collector.calls.length < minSequence) return;

    // Report the member's name rather than each call: the fix is to restructure
    // the body as one chain, which is a single edit at this level. Reporting
    // every `.run()` would suggest the opposite — that each one is separately
    // wrong.
    rule.reportAtToken(name, arguments: ['${collector.calls.length}']);
  }
}

/// Collects `.run()` calls on fpdart types, not descending into closures.
///
/// A closure has its own boundary: a callback passed to a widget or a handler
/// legitimately runs its own pipeline, and counting those against the
/// enclosing member would report a body that is already correct.
class _RunCallCollector extends RecursiveAstVisitor<void> {
  final calls = <MethodInvocation>[];

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Deliberately does not descend.
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'run') {
      final targetType = node.realTarget?.staticType;
      if (targetType != null &&
          lazyFpdartChecker.isAssignableFromType(targetType)) {
        calls.add(node);
      }
    }

    super.visitMethodInvocation(node);
  }
}
