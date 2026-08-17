import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when `Future.ignore()` silently discards an error without explaining
/// why that is intentional.
///
/// Unlike `unawaited(future)`, `future.ignore()` consumes both the value and
/// any error. An immediately preceding comment is treated as documentation of
/// that deliberate choice and leaves the call alone.
class AvoidFutureIgnore extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_future_ignore',
    "Avoid calling 'Future.ignore()' without explaining why errors may be "
        'discarded.',
    correctionMessage:
        'Await the future, pass it to unawaited(), handle its error, or add an '
        'adjacent comment when suppressing the error is intentional.',
  );

  AvoidFutureIgnore()
    : super(
        name: 'avoid_future_ignore',
        description:
            'Warns when Future.ignore() silently suppresses asynchronous '
            'errors without an adjacent explanatory comment.',
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
  final AvoidFutureIgnore rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'ignore' ||
        node.argumentList.arguments.isNotEmpty) {
      return;
    }

    // Resolve the declaration instead of matching only the spelling. A class
    // may legitimately declare its own `ignore()` method, and that method does
    // not have FutureExtensions' error-swallowing semantics.
    final element = node.methodName.element;
    if (element?.library?.identifier != 'dart:async' ||
        element?.enclosingElement?.name != 'FutureExtensions') {
      return;
    }

    if (_hasAdjacentExplanation(node)) return;
    rule.reportAtNode(node);
  }

  static bool _hasAdjacentExplanation(MethodInvocation node) {
    final unit = node.thisOrAncestorOfType<CompilationUnit>();
    if (unit == null) return false;

    final callLine = unit.lineInfo.getLocation(node.offset).lineNumber;
    for (
      Token? comment = node.beginToken.precedingComments;
      comment != null;
      comment = comment.next
    ) {
      final commentEndLine = unit.lineInfo.getLocation(comment.end).lineNumber;
      if (commentEndLine >= callLine - 1) return true;
    }
    return false;
  }
}
