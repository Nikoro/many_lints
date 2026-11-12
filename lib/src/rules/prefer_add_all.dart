import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

class PreferAddAll extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_add_all',
    "Elements are added one at a time and can be replaced with 'addAll'.",
    correctionMessage: "Use 'addAll' with the source collection instead.",
  );

  PreferAddAll()
    : super(
        name: 'prefer_add_all',
        description:
            'Warns when elements are added to a collection one at a time '
            'instead of with a single addAll() call.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
    registry.addBlock(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferAddAll rule;

  _Visitor(this.rule);

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

  @override
  void visitForStatement(ForStatement node) {
    final parts = node.forLoopParts;
    if (parts is! ForEachPartsWithDeclaration) return;

    final loopVariable = parts.loopVariable.declaredFragment?.element;
    if (loopVariable == null) return;

    final iterableType = parts.iterable.staticType;
    if (iterableType == null) return;
    if (!_iterableChecker.isAssignableFromType(iterableType)) return;

    final call = _soleStatement(node.body);
    if (call is! ExpressionStatement) return;

    final invocation = call.expression;
    if (invocation is! MethodInvocation) return;
    if (invocation.methodName.name != 'add') return;

    final target = invocation.realTarget;
    if (target == null) return;

    // Edge case: a receiver built from the loop item is a different collection per iteration
    final targetVisitor = _ElementReferenceVisitor(loopVariable);
    target.accept(targetVisitor);
    if (targetVisitor.found) return;

    final arguments = invocation.argumentList.arguments;
    if (arguments.length != 1) return;

    final argument = arguments.first;
    if (argument is! SimpleIdentifier) return;
    if (argument.element != loopVariable) return;

    rule.reportAtNode(node);
  }

  Statement? _soleStatement(Statement body) => switch (body) {
    Block(:final statements) when statements.length == 1 => statements.first,
    ExpressionStatement() => body,
    _ => null,
  };

  @override
  void visitBlock(Block node) {
    String? runReceiver;
    var runLength = 0;
    MethodInvocation? runSecondCall;

    void flush() {
      if (runLength > 1 && runSecondCall != null) {
        rule.reportAtNode(runSecondCall!);
      }
      runReceiver = null;
      runLength = 0;
      runSecondCall = null;
    }

    for (final statement in node.statements) {
      final receiver = _addReceiver(statement);

      if (receiver == null) {
        flush();
        continue;
      }

      if (receiver.name != runReceiver) {
        flush();
        runReceiver = receiver.name;
        runLength = 1;
        continue;
      }

      runLength++;
      runSecondCall ??= receiver.invocation;
    }

    flush();
  }

  ({String name, MethodInvocation invocation})? _addReceiver(
    Statement statement,
  ) {
    if (statement is! ExpressionStatement) return null;

    final invocation = statement.expression;
    if (invocation is! MethodInvocation) return null;
    if (invocation.methodName.name != 'add') return null;
    if (invocation.argumentList.arguments.length != 1) return null;

    final target = invocation.realTarget;
    if (target == null) return null;
    if (!_isStableReceiver(target)) return null;

    final targetType = target.staticType;
    if (targetType == null) return null;
    if (!_iterableChecker.isAssignableFromType(targetType)) return null;

    return (name: target.toSource(), invocation: invocation);
  }

  bool _isStableReceiver(Expression expression) => switch (expression) {
    SimpleIdentifier() => true,
    PrefixedIdentifier() => true,
    PropertyAccess(:final target) =>
      target == null || _isStableReceiver(target),
    _ => false,
  };
}

class _ElementReferenceVisitor extends RecursiveAstVisitor<void> {
  _ElementReferenceVisitor(this.element);

  final Object element;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == element) found = true;
  }
}
