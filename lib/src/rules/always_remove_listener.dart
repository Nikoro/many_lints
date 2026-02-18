import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a listener is added in a State lifecycle method but never
/// removed in `dispose()`.
///
/// Every `addListener()` call on a `Listenable` (e.g. `ValueNotifier`,
/// `ChangeNotifier`, `AnimationController`) inside `initState`,
/// `didUpdateWidget`, or `didChangeDependencies` must have a corresponding
/// `removeListener()` call in `dispose()` to prevent memory leaks.
class AlwaysRemoveListener extends AnalysisRule {
  static const LintCode code = LintCode(
    'always_remove_listener',
    'Listener added but never removed in dispose().',
    correctionMessage:
        'Add a matching removeListener() call in dispose() to prevent memory leaks.',
  );

  AlwaysRemoveListener()
    : super(
        name: 'always_remove_listener',
        description:
            'Warns when addListener() is called in a State lifecycle '
            'method without a matching removeListener() in dispose().',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AlwaysRemoveListener rule;

  _Visitor(this.rule);

  static const _stateChecker = TypeChecker.fromName(
    'State',
    packageName: 'flutter',
  );

  static const _lifecycleMethods = {
    'initState',
    'didUpdateWidget',
    'didChangeDependencies',
  };

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    if (!_stateChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    final methods = body.members.whereType<MethodDeclaration>();

    // Collect all removeListener calls in dispose()
    final disposeMethod = methods
        .where((m) => m.name.lexeme == 'dispose')
        .firstOrNull;
    final removeListenerCalls = <_ListenerCall>{};
    if (disposeMethod != null) {
      final collector = _MethodCallCollector(
        'removeListener',
        stopAtFunctions: true,
      );
      disposeMethod.body.visitChildren(collector);
      removeListenerCalls.addAll(collector.calls);
    }

    // Check lifecycle methods for addListener calls
    for (final method in methods) {
      if (!_lifecycleMethods.contains(method.name.lexeme)) continue;

      final collector = _MethodCallCollector(
        'addListener',
        stopAtFunctions: true,
      );
      method.body.visitChildren(collector);

      for (final addCall in collector.calls) {
        // Check if there's a matching removeListener in dispose
        if (!_hasMatchingRemoveListener(addCall, removeListenerCalls)) {
          rule.reportAtNode(addCall.node);
        }
      }
    }
  }

  static bool _hasMatchingRemoveListener(
    _ListenerCall addCall,
    Set<_ListenerCall> removeCalls,
  ) {
    for (final removeCall in removeCalls) {
      // The target (object being listened to) must match
      if (addCall.targetSource != removeCall.targetSource) continue;

      // The listener callback must match
      if (addCall.listenerSource != removeCall.listenerSource) continue;

      return true;
    }
    return false;
  }
}

/// Represents an addListener() or removeListener() call with its context.
class _ListenerCall {
  final MethodInvocation node;
  final String targetSource;
  final String listenerSource;

  _ListenerCall({
    required this.node,
    required this.targetSource,
    required this.listenerSource,
  });

  @override
  int get hashCode => Object.hash(targetSource, listenerSource);

  @override
  bool operator ==(Object other) =>
      other is _ListenerCall &&
      targetSource == other.targetSource &&
      listenerSource == other.listenerSource;
}

/// Collects all calls to a specific method (addListener or removeListener).
class _MethodCallCollector extends RecursiveAstVisitor<void> {
  final String methodName;
  final bool stopAtFunctions;
  final List<_ListenerCall> calls = [];

  _MethodCallCollector(this.methodName, {this.stopAtFunctions = false});

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == methodName) {
      final args = node.argumentList.arguments;
      if (args.isNotEmpty) {
        final target = node.realTarget;
        final targetSource = target?.toSource() ?? 'this';
        final listenerSource = args.first.toSource();

        calls.add(
          _ListenerCall(
            node: node,
            targetSource: targetSource,
            listenerSource: listenerSource,
          ),
        );
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (stopAtFunctions) return;
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (stopAtFunctions) return;
    super.visitFunctionDeclaration(node);
  }
}
