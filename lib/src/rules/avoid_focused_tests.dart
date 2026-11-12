import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../test_invocation.dart';

class AvoidFocusedTests extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_focused_tests',
    'This test is focused, so every other test in the file is silently '
        'skipped.',
    correctionMessage:
        'Remove `solo:`. It is a debugging aid, not something to commit.',
  );

  AvoidFocusedTests()
    : super(
        name: 'avoid_focused_tests',
        description: 'Warns when a test or group is focused with `solo:`.',
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
  final AvoidFocusedTests rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!isTestOrGroupInvocation(node)) return;

    final solo = namedArgument(node, 'solo');
    if (solo == null) return;

    final value = solo.argumentExpression;
    if (value is BooleanLiteral && !value.value) return;

    rule.reportAtNode(solo);
  }
}
