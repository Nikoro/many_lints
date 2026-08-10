import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when a synchronous `Either` step is lifted into a `TaskEither`
/// pipeline by hand.
///
/// `chainEither` is `flatMap` for a step that is synchronous and failable: it
/// takes the `Either`-returning function directly and does the lifting itself.
/// Writing `flatMap((x) => sync(x).toTaskEither())` re-implements that, and the
/// `toTaskEither()` at the end of the callback is easy to lose in a chain of
/// several such steps — where its absence is a type error rather than a
/// behaviour change, but its presence is pure noise.
///
/// **Bad:**
/// ```dart
/// pipeline.flatMap((body) => decode(body).toTaskEither());
/// ```
///
/// **Good:**
/// ```dart
/// pipeline.chainEither(decode);
/// ```
class PreferChainEither extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_chain_either',
    "Use 'chainEither' instead of lifting an 'Either' into 'flatMap'.",
    correctionMessage:
        "Pass the 'Either'-returning step to 'chainEither', which lifts it "
        'for you.',
  );

  PreferChainEither()
    : super(
        name: 'prefer_chain_either',
        description:
            'Warns when a synchronous Either step is lifted into a TaskEither '
            'pipeline with toTaskEither() inside flatMap, which chainEither '
            'already does.',
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
  final PreferChainEither rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'flatMap') return;

    final targetType = node.realTarget?.staticType;
    if (targetType == null) return;
    if (!taskEitherChecker.isAssignableFromType(targetType)) return;

    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return;

    final callback = arguments.first.argumentExpression;
    if (callback is! FunctionExpression) return;

    final returned = _returnedExpression(callback.body);
    if (returned == null) return;

    // The callback's whole job must be `<something>.toTaskEither()`; anything
    // else it does would be lost by the rewrite.
    if (returned is! MethodInvocation) return;
    if (returned.methodName.name != 'toTaskEither') return;

    final liftedType = returned.realTarget?.staticType;
    if (liftedType == null) return;
    if (!eitherChecker.isAssignableFromType(liftedType)) return;

    rule.reportAtNode(node.methodName);
  }

  /// The single expression [body] evaluates to, or null when it does more than
  /// return one thing.
  Expression? _returnedExpression(FunctionBody body) {
    if (body is ExpressionFunctionBody) return body.expression;

    if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.length != 1) return null;

      final statement = statements.first;
      return statement is ReturnStatement ? statement.expression : null;
    }

    return null;
  }
}
