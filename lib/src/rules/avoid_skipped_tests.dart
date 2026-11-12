import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../test_invocation.dart';

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
    final isExplicitlyNotSkipped = value is BooleanLiteral && !value.value;
    if (isExplicitlyNotSkipped) return;

    final hasReason = value is! BooleanLiteral;
    if (hasReason &&
        rule.config.boolOption('allow_reason', defaultValue: false)) {
      return;
    }

    rule.reportAtNode(skip, arguments: [kind]);
  }

  @override
  void visitAnnotation(Annotation node) {
    if (node.name.name != 'Skip') return;
    if (node.parent is! LibraryDirective) return;

    rule.reportAtNode(node, arguments: ['library']);
  }
}
