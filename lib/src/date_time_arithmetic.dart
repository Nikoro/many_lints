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
  static DateTimeShift? tryRead(MethodInvocation node) {
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

    final amount = _readDayAmount(argument);
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
_DayAmount? _readDayAmount(Expression argument) {
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

  return null;
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
