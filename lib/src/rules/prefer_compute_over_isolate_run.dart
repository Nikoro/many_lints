import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when `Isolate.run()` is used instead of `compute()`.
///
/// `Isolate.run()` lacks web platform support, making `compute()` from
/// `package:flutter/foundation.dart` the preferred alternative for
/// cross-platform Flutter applications.
///
/// ## Example
///
/// ❌ Bad:
/// ```dart
/// final result = await Isolate.run(() => expensiveWork());
/// ```
///
/// ✅ Good:
/// ```dart
/// final result = await compute((_) => expensiveWork(), null);
/// ```
class PreferComputeOverIsolateRun extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_compute_over_isolate_run',
    "Use 'compute()' instead of 'Isolate.run()' for web platform "
        'compatibility.',
    correctionMessage:
        "Replace with 'compute()' from 'package:flutter/foundation.dart'.",
  );

  PreferComputeOverIsolateRun()
    : super(
        name: 'prefer_compute_over_isolate_run',
        description: 'Warns when Isolate.run() is used instead of compute().',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferComputeOverIsolateRun rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'run') return;

    final target = node.target;
    if (target is! SimpleIdentifier) return;
    if (target.name != 'Isolate') return;

    // Verify the target resolves to dart:isolate's Isolate class
    final element = target.element;
    if (element == null) return;
    final library = element.library;
    if (library == null) return;
    if (!library.identifier.startsWith('dart:isolate')) return;

    rule.reportAtNode(node);
  }
}
