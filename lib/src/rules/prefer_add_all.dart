import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when several elements are added to a collection one at a time.
///
/// Two shapes are reported:
///
/// 1. A `for-in` loop whose only statement adds the loop variable —
///    `for (final x in source) target.add(x);` is `target.addAll(source)`
///    written out, with control flow the reader has to decode.
/// 2. Consecutive `add` calls on the same receiver — `target.add(a);
///    target.add(b);` is `target.addAll([a, b])`.
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

    // `groups.putIfAbsent(keyOf(item), () => []).add(item)` distributes the
    // source across a different target per iteration. There is no equivalent
    // `addAll` call when the receiver itself depends on the loop variable.
    final targetVisitor = _ElementReferenceVisitor(loopVariable);
    target.accept(targetVisitor);
    if (targetVisitor.found) return;

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

  /// Reports runs of consecutive `add` calls on the same receiver.
  ///
  /// `target.add(a); target.add(b);` is `target.addAll([a, b])`. A run is
  /// broken by any other statement, so unrelated work between the calls
  /// keeps them separate.
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

  /// Returns the receiver of a lone `receiver.add(value)` statement.
  ///
  /// Only a stable receiver is returned: comparing by source is sound for an
  /// identifier or property chain, but `list()..add(x)` or `map[k].add(x)`
  /// may denote a different object on each call.
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

    // Only collections: `add` exists on many unrelated types.
    final targetType = target.staticType;
    if (targetType == null) return null;
    if (!_iterableChecker.isAssignableFromType(targetType)) return null;

    return (name: target.toSource(), invocation: invocation);
  }

  /// Whether [expression] denotes the same object every time it appears.
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
