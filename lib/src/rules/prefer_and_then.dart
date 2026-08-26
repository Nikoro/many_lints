import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_chain_call.dart';
import '../many_lints_rule.dart';

/// Warns when `flatMap` ignores the value it is handed, which is what
/// `andThen` is for.
///
/// fpdart declares `andThen` as literally `flatMap((_) => then())`, so this is
/// not a behaviour change — it is the same call under the name that says what
/// it does. A reader scanning a pipeline has to open the callback of every
/// `flatMap` to learn whether the previous value matters; `andThen` answers
/// that in the name.
///
/// Only the provably-ignored case is reported. A callback that reads its
/// parameter has a real dependency on the previous step, and `andThen` throws
/// that value away, so the check is by element rather than by the `_`
/// spelling: a named-but-unused parameter is the same situation, and a used
/// one is disqualifying whatever it is called.
///
/// **Bad:**
/// ```dart
/// resetter.reset().flatMap((_) => authRepository.logout());
/// ```
///
/// **Good:**
/// ```dart
/// resetter.reset().andThen(authRepository.logout);
/// ```
class PreferAndThen extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_and_then',
    "Use 'andThen' when the previous value is not used.",
    correctionMessage:
        "Replace 'flatMap' with 'andThen', which takes a callback that "
        'receives nothing.',
  );

  PreferAndThen()
    : super(
        name: 'prefer_and_then',
        description:
            'Warns when flatMap ignores its argument, which is what andThen '
            'expresses.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferAndThen rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'flatMap') return;

    // Read from this node only: `readFpdartFlatMap` walks up the parent chain
    // for an assist's cursor, and the enclosing chain is not what is being
    // visited here.
    final call = readFpdartFlatMap(node);
    if (call == null || call.invocation != node) return;

    final body = call.body;
    if (body == null) return;

    if (!parameterIsUnused(call.parameter, body)) return;

    rule.reportAtNode(node.methodName);
  }
}
