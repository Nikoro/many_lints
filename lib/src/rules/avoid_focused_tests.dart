import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../test_invocation.dart';

/// Warns when a test or group is focused with `solo:`.
///
/// This is the mirror of [avoid_skipped_tests] and the more dangerous half. A
/// skipped test silences itself, and the runner's summary at least counts it.
/// A soloed test silences *every sibling in the file* — they are not reported
/// as skipped so much as never considered, and the run still exits zero.
///
/// `solo` is a debugging aid: it is how you narrow a run while chasing one
/// failure. The defect is committing it. Nobody intends to, which is precisely
/// why it needs a rule rather than a code-review habit — the diff looks like
/// one word.
///
/// There is deliberately no option to permit it. Unlike a skip, a focus has no
/// documented-and-therefore-tolerable form: a reason string would not make the
/// other tests run.
///
/// **BAD:**
/// ```dart
/// test('the one I am debugging', () { ... }, solo: true);  // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// test('the one I am debugging', () { ... });
/// ```
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

    // `solo: false` is the default written out, which suppresses nothing.
    final value = solo.argumentExpression;
    if (value is BooleanLiteral && !value.value) return;

    rule.reportAtNode(solo);
  }
}
