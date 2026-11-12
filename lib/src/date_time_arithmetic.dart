import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import 'type_checker.dart';

const _dateTimeChecker = TypeChecker.fromUrl('dart:core#DateTime');
const _durationChecker = TypeChecker.fromUrl('dart:core#Duration');

class DateTimeShift {
  final MethodInvocation invocation;

  final Expression receiver;

  final bool isSubtraction;

  final int? literalDays;

  const DateTimeShift({
    required this.invocation,
    required this.receiver,
    required this.isSubtraction,
    required this.literalDays,
  });

  static DateTimeShift? tryRead(MethodInvocation node, {RuleContext? context}) {
    final isSubtraction = switch (node.methodName.name) {
      'add' => false,
      'subtract' => true,
      _ => null,
    };
    if (isSubtraction == null) return null;

    final receiver = node.realTarget;
    if (receiver == null) return null;
    final receiverType = receiver.staticType;
    if (receiverType == null) return null;
    if (!_dateTimeChecker.isExactlyType(receiverType)) return null;

    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return null;
    final argument = arguments.single;
    if (argument is! Expression) return null;

    final amount = _readDayAmount(argument, context);
    if (amount == null) return null;

    return DateTimeShift(
      invocation: node,
      receiver: receiver,
      isSubtraction: isSubtraction,
      literalDays: amount.literalDays,
    );
  }

  bool get isUtcReceiver => _isUtc(receiver);

  static bool _isUtc(Expression expression) {
    final unwrapped = expression.unParenthesized;

    if (unwrapped case MethodInvocation(
      methodName: SimpleIdentifier(name: 'toUtc'),
    )) {
      return true;
    }

    if (unwrapped case InstanceCreationExpression(
      constructorName: ConstructorName(name: SimpleIdentifier(name: 'utc')),
    )) {
      return true;
    }

    if (unwrapped case MethodInvocation(
      methodName: SimpleIdentifier(name: 'add' || 'subtract'),
      realTarget: final inner?,
    )) {
      return _isUtc(inner);
    }

    if (unwrapped case SimpleIdentifier(element: final element?)) {
      return _isUtcVariable(element, unwrapped);
    }

    return false;
  }

  static bool _isUtcVariable(Element element, AstNode reference) {
    if (element is! LocalVariableElement) return false;

    for (
      var body = reference.thisOrAncestorOfType<FunctionBody>();
      body != null;
      body = body.parent?.thisOrAncestorOfType<FunctionBody>()
    ) {
      final finder = _InitializerFinder(element);
      body.accept(finder);

      final initializer = finder.initializer;
      if (initializer != null) return _isUtc(initializer);
    }

    return false;
  }
}

class _DayAmount {
  final int? literalDays;

  const _DayAmount(this.literalDays);
}

_DayAmount? _readDayAmount(Expression argument, [RuleContext? context]) {
  final unwrapped = argument.unParenthesized;

  if (unwrapped case InstanceCreationExpression(
    constructorName: ConstructorName(type: final type),
    argumentList: final argumentList,
  )) {
    final element = type.element;
    if (element == null || !_durationChecker.isExactly(element)) return null;

    return _readDayArguments(argumentList);
  }

  // Edge case: the fix passes no context, so it only ever sees Duration literals
  if (context == null) return null;

  return _readDayAmountFromName(argument.unParenthesized, context);
}

_DayAmount? _readDayAmountFromName(Expression expression, RuleContext context) {
  final type = expression.staticType;
  if (type == null || !_durationChecker.isExactlyType(type)) return null;

  final element = switch (expression) {
    PropertyAccess(propertyName: SimpleIdentifier(element: final element?)) =>
      element,
    Identifier(element: final element?) => element,
    _ => null,
  };
  if (element == null) return null;

  // Edge case: computeConstantValue does not reach a non-const local, so read the AST
  if (element is LocalVariableElement) {
    final initializer = _localInitializer(element, expression);
    return initializer == null ? null : _readDayAmount(initializer);
  }

  if (_readDayAmountFromConstant(element) case final amount?) return amount;

  return _readDayAmountFromGetterBody(element, context);
}

Expression? _localInitializer(Element element, AstNode reference) {
  final body = reference.thisOrAncestorOfType<FunctionBody>();
  if (body == null) return null;

  final finder = _InitializerFinder(element);
  body.accept(finder);

  return finder.initializer;
}

_DayAmount? _readDayAmountFromConstant(Element element) {
  final variable = switch (element) {
    PropertyAccessorElement(variable: final variable) => variable,
    VariableElement() => element,
    _ => null,
  };

  final invocation = variable?.computeConstantValue()?.constructorInvocation;
  if (invocation == null) return null;

  var days = 0;
  var sawDayComponent = false;

  for (final MapEntry(key: name, value: argument)
      in invocation.namedArguments.entries) {
    switch (name) {
      case 'days':
        final literal = argument.toIntValue();
        if (literal == null) return null;
        if (literal != 0) sawDayComponent = true;
        days += literal;

      case 'hours':
        final literal = argument.toIntValue();
        if (literal == null || literal % 24 != 0) return null;
        if (literal != 0) sawDayComponent = true;
        days += literal ~/ 24;

      case 'minutes' || 'seconds' || 'milliseconds' || 'microseconds':
        if (argument.toIntValue() != 0) return null;

      default:
        return null;
    }
  }

  if (!sawDayComponent || days == 0) return null;

  // Edge case: the call site has no literal for the fix to rewrite
  return const _DayAmount(null);
}

_DayAmount? _readDayAmountFromGetterBody(Element element, RuleContext context) {
  if (element is! GetterElement) return null;

  final declaration = _findDeclaration(element, context);
  if (declaration is! MethodDeclaration) return null;

  final body = declaration.body;
  if (body is! ExpressionFunctionBody) return null;

  final returned = body.expression.unParenthesized;
  if (returned is! InstanceCreationExpression) return null;

  final constructedType = returned.constructorName.type.element;
  if (constructedType == null) return null;
  if (!_durationChecker.isExactly(constructedType)) return null;

  final amount = _readDayArguments(returned.argumentList);
  if (amount == null) return null;

  return const _DayAmount(null);
}

AstNode? _findDeclaration(Element element, RuleContext context) {
  for (final unit in context.allUnits) {
    final finder = _DeclarationFinder(element);
    unit.unit.accept(finder);
    if (finder.declaration != null) return finder.declaration;
  }
  return null;
}

class _DeclarationFinder extends RecursiveAstVisitor<void> {
  final Element _target;

  AstNode? declaration;

  _DeclarationFinder(this._target);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.declaredFragment?.element == _target) declaration = node;
    super.visitMethodDeclaration(node);
  }
}

_DayAmount? _readDayArguments(ArgumentList argumentList) {
  var days = 0;
  var sawDayComponent = false;
  var isLiteral = true;

  for (final argument in argumentList.arguments) {
    if (argument is! NamedArgument) return null;

    final name = argument.name.lexeme;
    final value = argument.argumentExpression;

    switch (name) {
      case 'days':
        sawDayComponent = true;
        if (value case IntegerLiteral(value: final literal?)) {
          days += literal;
        } else {
          isLiteral = false;
        }

      case 'hours':
        if (value case IntegerLiteral(
          value: final literal?,
        ) when literal != 0 && literal % 24 == 0) {
          sawDayComponent = true;
          days += literal ~/ 24;
        } else {
          return null;
        }

      case 'minutes' || 'seconds' || 'milliseconds' || 'microseconds':
        if (value case IntegerLiteral(value: 0)) continue;
        return null;

      default:
        return null;
    }
  }

  if (!sawDayComponent) return null;
  if (isLiteral && days == 0) return null;

  return _DayAmount(isLiteral ? days : null);
}

class _InitializerFinder extends RecursiveAstVisitor<void> {
  final Element _target;

  Expression? initializer;

  _InitializerFinder(this._target);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.declaredFragment?.element == _target) {
      initializer = node.initializer;
    }
    super.visitVariableDeclaration(node);
  }
}
