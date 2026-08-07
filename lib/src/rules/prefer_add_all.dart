import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a `for-in` loop does nothing but add each element to a
/// collection.
///
/// `for (final x in source) target.add(x);` is `target.addAll(source)`
/// written out. The loop form hides a simple operation behind control flow
/// the reader has to decode.
class PreferAddAll extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_add_all',
    "This loop only adds elements and can be replaced with 'addAll'.",
    correctionMessage: "Use 'addAll' with the source collection instead.",
  );

  PreferAddAll()
    : super(
        name: 'prefer_add_all',
        description:
            'Warns when a for-in loop only calls add() and could be an '
            'addAll() call.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferAddAll rule;

  _Visitor(this.rule);

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

  @override
  void visitForStatement(ForStatement node) {
    final parts = node.forLoopParts;
    // Only `for (final x in source)` — an indexed loop may skip or reorder.
    if (parts is! ForEachPartsWithDeclaration) return;

    final loopVariable = parts.loopVariable.declaredFragment?.element;
    if (loopVariable == null) return;

    // The source must be an iterable we can hand to addAll directly.
    final iterableType = parts.iterable.staticType;
    if (iterableType == null) return;
    if (!_iterableChecker.isAssignableFromType(iterableType)) return;

    final call = _soleStatement(node.body);
    if (call is! ExpressionStatement) return;

    final invocation = call.expression;
    if (invocation is! MethodInvocation) return;
    if (invocation.methodName.name != 'add') return;

    // A qualified target is required: `target.add(x)`, not a bare `add(x)`.
    final target = invocation.realTarget;
    if (target == null) return;

    final arguments = invocation.argumentList.arguments;
    if (arguments.length != 1) return;

    // The argument must be the loop variable itself, unchanged. Anything
    // else — `target.add(x.name)` — is a map, not a copy.
    final argument = arguments.first;
    if (argument is! SimpleIdentifier) return;
    if (argument.element != loopVariable) return;

    rule.reportAtNode(node);
  }

  /// Returns the single statement of [body], unwrapping a one-statement
  /// block.
  Statement? _soleStatement(Statement body) => switch (body) {
    Block(:final statements) when statements.length == 1 => statements.first,
    ExpressionStatement() => body,
    _ => null,
  };
}
