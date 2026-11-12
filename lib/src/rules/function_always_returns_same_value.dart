import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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
    _reportIfOneConstantAnswer(node.functionExpression.body, node.name);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    if (_isProtocolCallback(node.name.lexeme)) return;

    if (_takesANotification(node.parameters)) return;

    _reportIfOneConstantAnswer(node.body, node.name);
  }

  bool _takesANotification(FormalParameterList? parameters) {
    if (parameters == null) return false;

    return parameters.parameters.any((parameter) {
      final type = parameter.declaredFragment?.element.type;
      return type is InterfaceType &&
          (type.element.name?.endsWith('Notification') ?? false);
    });
  }

  bool _isProtocolCallback(String name) =>
      _protocolCallbacks.contains(name) || _isOnEventHandlerName(name);

  bool _isOnEventHandlerName(String name) =>
      name.startsWith('on') &&
      name.length > 2 &&
      name[2] == name[2].toUpperCase();

  void _reportIfOneConstantAnswer(FunctionBody body, Token name) {
    if (body is! BlockFunctionBody) return;

    final collector = _ReturnCollector();
    body.block.accept(collector);

    if (collector.hasUnprovableReturn) return;
    if (collector.values.length < 2) return;

    final first = collector.values.first;
    if (collector.values.any((value) => value != first)) return;

    rule.reportAtToken(name, arguments: [first]);
  }
}

class _ReturnCollector extends RecursiveAstVisitor<void> {
  final values = <String>[];

  bool hasUnprovableReturn = false;

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;

    if (expression == null) {
      hasUnprovableReturn = true;
      return;
    }

    if (_constantSource(expression) case final source?) {
      values.add(source);
    } else {
      hasUnprovableReturn = true;
    }
  }

  // Edge case: a nested closure's returns belong to the closure, not the enclosing function
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
