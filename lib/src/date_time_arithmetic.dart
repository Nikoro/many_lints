import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import 'type_checker.dart';

const _dateTimeChecker = TypeChecker.fromUrl('dart:core#DateTime');
const _durationChecker = TypeChecker.fromUrl('dart:core#Duration');

/// A `dateTime.add(...)` / `dateTime.subtract(...)` call whose `Duration`
/// argument moves the value by a whole number of days.
///
/// Shared by `avoid_dst_unsafe_date_arithmetic` and its fix so the two cannot
/// disagree about what counts as day-granularity arithmetic.
class DateTimeShift {
  /// The whole invocation, `receiver.add(Duration(days: 1))`.
  final MethodInvocation invocation;

  /// The receiver the duration is applied to.
  final Expression receiver;

  /// `true` for `subtract`, `false` for `add`.
  final bool isSubtraction;

  /// The number of days the call shifts by, when it is a single integer
  /// literal `days:` argument. `null` when the amount is not statically a
  /// plain literal — the rule still reports, but the fix declines.
  final int? literalDays;

  const DateTimeShift({
    required this.invocation,
    required this.receiver,
    required this.isSubtraction,
    required this.literalDays,
  });

  /// Reads [node] as a day-granularity `DateTime` shift, or returns `null`.
  ///
  /// Returns `null` for sub-day durations: `Duration(hours: 2)` is genuinely
  /// absolute elapsed time, so applying it with a `Duration` is correct.
  ///
  /// [context] lets a `Duration` reached through a name be resolved back to
  /// the declaration it came from. Without it only a literal at the call site
  /// is read, which is all the fix needs: there is no literal to rewrite in
  /// the indirect case anyway.
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

  /// Whether the receiver is statically known to be a UTC `DateTime`.
  ///
  /// UTC has no daylight saving transitions, so `Duration` arithmetic on it is
  /// exact. Only syntactically evident cases count — `DateTime.utc(...)`,
  /// `.toUtc()`, and a local variable initialised from either. Anything else
  /// would need flow analysis this rule deliberately does not attempt.
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

    // A chained shift keeps the receiver's zone: `utcValue.add(d).add(d)`.
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

  /// Resolves a local variable back to its initializer to see if it is UTC.
  ///
  /// Scoped to the enclosing function body: a field or top-level variable is
  /// left alone, because it may be reassigned anywhere.
  static bool _isUtcVariable(Element element, AstNode reference) {
    if (element is! LocalVariableElement) return false;

    final body = reference.thisOrAncestorOfType<FunctionBody>();
    if (body == null) return false;

    final finder = _InitializerFinder(element);
    body.accept(finder);

    final initializer = finder.initializer;
    if (initializer == null) return false;

    return _isUtc(initializer);
  }
}

/// The unit a `Duration` literal moves by, when it is day-granularity.
class _DayAmount {
  final int? literalDays;

  const _DayAmount(this.literalDays);
}

/// Reads a `Duration` argument as a whole-day amount, or returns `null`.
_DayAmount? _readDayAmount(Expression argument, [RuleContext? context]) {
  final unwrapped = argument.unParenthesized;

  // `const Duration(days: 1)` and `Duration(days: 1)`.
  if (unwrapped case InstanceCreationExpression(
    constructorName: ConstructorName(type: final type),
    argumentList: final argumentList,
  )) {
    final element = type.element;
    if (element == null || !_durationChecker.isExactly(element)) return null;

    return _readDayArguments(argumentList);
  }

  // A `Duration` reached through a name — `leadTime.offsetFromEvent`, a
  // constant, a local — carries the same defect as a literal, and a name is
  // how it survives review. Resolving it needs the library's elements, which
  // only a rule has, so the fix (which passes no context) keeps seeing just
  // literals.
  if (context == null) return null;

  return _readDayAmountFromName(argument.unParenthesized, context);
}

/// Follows a `Duration`-typed name back to the declaration it came from.
///
/// Only a declaration that is itself day-granularity reports: most named
/// durations really are absolute (a 15-minute cooldown, an hour of backoff),
/// and reporting those on sight would bury the calendar bug in noise. A name
/// that cannot be resolved stays silent rather than being guessed at.
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

  // A local variable's initializer is right there in the enclosing function,
  // and `computeConstantValue` does not reach a non-const one, so read the
  // AST first.
  if (element is LocalVariableElement) {
    final initializer = _localInitializer(element, expression);
    return initializer == null ? null : _readDayAmount(initializer);
  }

  // A constant field or variable evaluates, and does so even when it is
  // declared in another library.
  if (_readDayAmountFromConstant(element) case final amount?) return amount;

  // A getter is code, not a constant, so nothing evaluates: its body has to
  // be read from the AST. That reaches only the library under analysis, which
  // is where the getters worth catching live — an enum's `Duration get`
  // beside the call site that misuses it.
  return _readDayAmountFromGetterBody(element, context);
}

/// The initializer of a local [element], found in the enclosing function.
Expression? _localInitializer(Element element, AstNode reference) {
  final body = reference.thisOrAncestorOfType<FunctionBody>();
  if (body == null) return null;

  final finder = _InitializerFinder(element);
  body.accept(finder);

  return finder.initializer;
}

/// Reads a `Duration` constant's value, across library boundaries.
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

      // `Duration(hours: 24)` is the same bug written differently.
      case 'hours':
        final literal = argument.toIntValue();
        if (literal == null || literal % 24 != 0) return null;
        if (literal != 0) sawDayComponent = true;
        days += literal ~/ 24;

      // Any sub-day component makes the duration genuinely absolute.
      case 'minutes' || 'seconds' || 'milliseconds' || 'microseconds':
        if (argument.toIntValue() != 0) return null;

      default:
        return null;
    }
  }

  if (!sawDayComponent || days == 0) return null;

  // The amount is deliberately not propagated: the fix rewrites a literal at
  // the call site, and there is no literal there to rewrite.
  return const _DayAmount(null);
}

/// Reads the `Duration` literal a getter returns, for a getter declared in
/// the library under analysis.
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

/// The AST node declaring [element], searched across the library's units.
AstNode? _findDeclaration(Element element, RuleContext context) {
  for (final unit in context.allUnits) {
    final finder = _DeclarationFinder(element);
    unit.unit.accept(finder);
    if (finder.declaration != null) return finder.declaration;
  }
  return null;
}

/// Finds the declaration of a specific element within a compilation unit.
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

/// Classifies the named arguments of a `Duration` constructor call.
///
/// Only a duration expressed purely in days (or whole multiples of 24 hours)
/// qualifies: a mixed `Duration(days: 1, hours: 2)` still carries a sub-day
/// component, which the calendar constructor cannot reproduce by bumping the
/// day component alone.
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
        // `Duration(hours: 24)` is the same bug written differently, but only
        // when it is a whole number of days.
        if (value case IntegerLiteral(
          value: final literal?,
        ) when literal != 0 && literal % 24 == 0) {
          sawDayComponent = true;
          days += literal ~/ 24;
        } else {
          return null;
        }

      // Any sub-day component makes the duration genuinely absolute.
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

/// Finds the initializer of a specific local variable within a subtree.
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
