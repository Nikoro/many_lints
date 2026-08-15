import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a no-argument method just reads a value and should be a getter.
///
/// `order.getTotal()` and `order.total` return the same thing, but only the
/// second reads as a property of the order. Effective Dart's rule is that a
/// member doing no real work and taking no arguments is a getter; the empty
/// parentheses otherwise suggest something happens when you call it.
///
/// Only a method whose body is a single expression is considered — one that
/// runs statements may well be doing the work the parentheses imply. A method
/// returning `void`, an operator, an override and anything taking parameters
/// are all left alone.
class PreferGetterOverMethod extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_getter_over_method',
    "'{0}' takes no arguments and computes nothing; make it a getter.",
    correctionMessage: "Declare it as 'get {0}' and drop the parentheses.",
  );

  PreferGetterOverMethod()
    : super(
        name: 'prefer_getter_over_method',
        description:
            'Warns when a no-argument method only reads a value, where a '
            'getter reads as the property it is.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

/// Methods whose call syntax is fixed by a convention outside this codebase.
///
/// `toJson` is what every serialiser looks for, `call` is the invocation
/// operator in all but name, and `copyWith`/`toList` are established shapes a
/// reader expects to see invoked.
const _conventionalMethods = <String>{
  'toJson',
  'toMap',
  'call',
  'copyWith',
  'toList',
  'toSet',
  'toString',
  'noSuchMethod',
};

class _Visitor extends SimpleAstVisitor<void> {
  final PreferGetterOverMethod rule;

  _Visitor(this.rule);

  /// Whether the body runs any code beyond reading fields.
  bool _invokesSomething(FunctionBody body) {
    final visitor = _InvocationFinder();
    body.accept(visitor);
    return visitor.found;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isGetter || node.isSetter || node.isOperator) return;

    // Names whose parentheses are a convention rather than a choice.
    if (_conventionalMethods.contains(node.name.lexeme)) return;

    // An override must keep the shape the supertype declared.
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    // A generic method is invoked with type arguments, which a getter cannot
    // take.
    if (node.typeParameters != null) return;

    if (node.parameters?.parameters.isNotEmpty ?? true) return;

    // `void` says the member is called for an effect, which is exactly what a
    // getter must not be.
    final returnType = node.returnType;
    if (returnType is NamedType && returnType.name.lexeme == 'void') return;
    if (returnType == null) return;

    // Only an expression body is a plain read. A block body may be doing the
    // work the parentheses promise.
    if (node.body is! ExpressionFunctionBody) return;

    // An async member returns a Future the caller awaits, which reads as work
    // rather than as a property.
    if (node.body.isAsynchronous || node.body.isGenerator) return;

    // A Stream is something you subscribe to, not a property you read, so
    // `watchUser()` keeps its parentheses.
    if (returnType is NamedType &&
        const {'Stream', 'Future'}.contains(returnType.name.lexeme)) {
      return;
    }

    // A body that calls something is not a plain read: `Clock.now()` and
    // `sixDigitCode()` answer differently on each call, and a getter promises
    // a stable property. Only a body built from field reads and operators
    // qualifies.
    if (_invokesSomething(node.body)) return;

    rule.reportAtToken(node.name, arguments: [node.name.lexeme]);
  }
}

/// Detects any call in a body, which makes it more than a property read.
class _InvocationFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    found = true;
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    found = true;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    found = true;
  }
}
