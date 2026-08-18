import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../test_invocation.dart';

/// Warns when a test, group or whole library is switched off in place.
///
/// A skipped test still counts as a test. `dart test` reports it as skipped
/// and exits zero, so every gate downstream stays green: CI passes, a
/// mirror-test presence check is satisfied because the file exists, and a
/// coverage gate sees the file counted but never executed. The suite grows
/// while the evidence it provides shrinks, and nothing in the output says so.
///
/// A reason string does not change that. `skip: 'flaky on CI'` makes the skip
/// readable, not acceptable — the test still proves nothing. Projects that
/// disagree can set `allow_reason: true`, which then reports only the bare
/// `skip: true` form.
///
/// `skip: false` is never reported: it is a no-op that occasionally appears as
/// a deliberate placeholder.
///
/// **BAD:**
/// ```dart
/// test('parses a malformed manifest', () { ... }, skip: true);  // LINT
///
/// @Skip('needs a real device')
/// library;                                                      // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// test('parses a malformed manifest', () { ... });
/// ```
class AvoidSkippedTests extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_skipped_tests',
    'This {0} is skipped and will not run.',
    correctionMessage:
        'Fix the test or delete it. A skipped test passes CI while proving '
        'nothing.',
  );

  AvoidSkippedTests()
    : super(
        name: 'avoid_skipped_tests',
        description: 'Warns when a test, group or library is skipped in place.',
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
    registry.addAnnotation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidSkippedTests rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final kind = testInvocationKind(node);
    if (kind == null) return;

    final skip = namedArgument(node, 'skip');
    if (skip == null) return;

    final value = skip.argumentExpression;
    // `skip: false` is a no-op, and so is anything that provably evaluates to
    // it. Only a literal `false` can be read without evaluating, which is
    // enough: the shape people actually write is `skip: true`.
    if (value is BooleanLiteral && !value.value) return;

    // With `allow_reason` the documented form is permitted and the bare
    // switch is not, so a project that wants an audit trail gets one without
    // the rule going silent.
    if (value is! BooleanLiteral &&
        rule.config.boolOption('allow_reason', defaultValue: false)) {
      return;
    }

    rule.reportAtNode(skip, arguments: [kind]);
  }

  @override
  void visitAnnotation(Annotation node) {
    // `@Skip(...)` on a library directive disables every test in the file, so
    // it is the highest-leverage form of the same defect.
    if (node.name.name != 'Skip') return;
    if (node.parent is! LibraryDirective) return;

    rule.reportAtNode(node, arguments: ['library']);
  }
}
