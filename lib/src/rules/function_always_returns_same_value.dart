import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when every `return` in a function yields the same constant.
///
/// The branching around those returns decides nothing: whatever the caller
/// passes, the answer is fixed. Either a branch was meant to return something
/// else and does not, or the function should be a constant and the parameters
/// dropped.
///
/// Only literal constants are compared, and only when there are at least two
/// returns — one return of a constant is an ordinary function.
class FunctionAlwaysReturnsSameValue extends ManyLintsRule {
  static const LintCode code = LintCode(
    'function_always_returns_same_value',
    "Every return in this function yields '{0}'.",
    correctionMessage:
        'Return the value each branch was meant to, or drop the branching.',
  );

  FunctionAlwaysReturnsSameValue()
    : super(
        name: 'function_always_returns_same_value',
        description:
            'Warns when all return statements in a function produce the same '
            'constant, so the branching around them changes nothing.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

/// Callbacks whose contract fixes the returned value.
///
/// Each is called by a framework that reads the result as a signal — "handled"
/// or "keep going" — so returning the same value everywhere is the contract
/// being met, not a branch that forgot to differ.
const _protocolCallbacks = <String>{
  'onNotification',
  'shouldRepaint',
  'shouldRebuild',
  'shouldReclip',
  'moveTo',
  'visitChildren',
};

class _Visitor extends SimpleAstVisitor<void> {
  final FunctionAlwaysReturnsSameValue rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _check(node.functionExpression.body, node.name);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // An override must keep its signature, and a one-value implementation is
    // a normal way to satisfy an interface.
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    // A callback whose return value is a protocol rather than an answer is
    // supposed to be constant. `onNotification` must return `false` on every
    // path to let a notification keep bubbling; the method exists for its
    // side effect.
    if (_isProtocolCallback(node.name.lexeme)) return;

    // A name-based check cannot catch a protocol callback given a descriptive
    // name, so also recognise the shape: a `bool` taking a Notification is
    // one, whatever it is called.
    if (_takesANotification(node.parameters)) return;

    _check(node.body, node.name);
  }

  /// Whether any parameter is a `Notification`, which makes this a listener
  /// callback whose `bool` is a "handled" signal rather than an answer.
  bool _takesANotification(FormalParameterList? parameters) {
    if (parameters == null) return false;

    return parameters.parameters.any((parameter) {
      final type = parameter.declaredFragment?.element.type;
      return type is InterfaceType &&
          (type.element.name?.endsWith('Notification') ?? false);
    });
  }

  /// Whether a name belongs to a callback whose return value is a fixed
  /// protocol signal rather than a computed answer.
  bool _isProtocolCallback(String name) =>
      _protocolCallbacks.contains(name) ||
      (name.startsWith('on') &&
          name.length > 2 &&
          name[2] == name[2].toUpperCase());

  void _check(FunctionBody body, Token name) {
    if (body is! BlockFunctionBody) return;

    final collector = _ReturnCollector();
    body.block.accept(collector);

    // A bare `return;` or a nested closure's return means the function does
    // not have one fixed answer this rule can prove.
    if (collector.bailedOut) return;
    if (collector.values.length < 2) return;

    final first = collector.values.first;
    if (collector.values.any((value) => value != first)) return;

    rule.reportAtToken(name, arguments: [first]);
  }
}

/// Collects the source of every constant returned directly by a function.
class _ReturnCollector extends RecursiveAstVisitor<void> {
  final values = <String>[];

  /// Set when something is returned that this rule cannot reason about.
  bool bailedOut = false;

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;

    // `return;` yields nothing to compare.
    if (expression == null) {
      bailedOut = true;
      return;
    }

    if (_constantSource(expression) case final source?) {
      values.add(source);
    } else {
      bailedOut = true;
    }
  }

  /// A nested function has its own returns, which say nothing about this one.
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  String? _constantSource(Expression expression) => switch (expression) {
    BooleanLiteral() ||
    IntegerLiteral() ||
    DoubleLiteral() ||
    SimpleStringLiteral() ||
    NullLiteral() => expression.toSource(),
    _ => null,
  };
}
