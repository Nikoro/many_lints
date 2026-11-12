import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_chain_call.dart';
import '../many_lints_rule.dart';

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

    // Edge case: the reader climbs to an enclosing flatMap for assists; that one has its own visit
    final call = readFpdartFlatMap(node);
    if (call == null || call.invocation != node) return;

    final body = call.body;
    if (body == null) return;

    if (!parameterIsUnused(call.parameter, body)) return;

    rule.reportAtNode(node.methodName);
  }
}
