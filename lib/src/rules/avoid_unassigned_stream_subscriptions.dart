import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a `Stream.listen()` call is not assigned to a variable.
///
/// Without storing the returned `StreamSubscription`, you cannot cancel it
/// later, which may lead to memory leaks.
class AvoidUnassignedStreamSubscriptions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unassigned_stream_subscriptions',
    'Stream subscription is not assigned to a variable.',
    correctionMessage:
        'Assign the result of listen() to a variable so you can cancel it.',
  );

  AvoidUnassignedStreamSubscriptions()
    : super(
        name: 'avoid_unassigned_stream_subscriptions',
        description:
            'Warns when a stream subscription is not assigned to a variable.',
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
  final AvoidUnassignedStreamSubscriptions rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'listen') return;

    // Check that the return type is StreamSubscription
    final returnType = node.staticType;
    if (returnType is! InterfaceType) return;
    if (!_isStreamSubscription(returnType)) return;

    // Only flag if used as an expression statement (not assigned, not returned,
    // not passed as an argument, etc.)
    if (node.parent is! ExpressionStatement) return;

    rule.reportAtNode(node);
  }

  static bool _isStreamSubscription(InterfaceType type) {
    if (type.element.name == 'StreamSubscription') {
      return type.element.library.identifier.startsWith('dart:async');
    }
    for (final supertype in type.element.allSupertypes) {
      if (supertype.element.name == 'StreamSubscription' &&
          supertype.element.library.identifier.startsWith('dart:async')) {
        return true;
      }
    }
    return false;
  }
}
