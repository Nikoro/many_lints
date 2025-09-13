import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import 'package:many_lints/src/type_checker.dart';

/// Checks whether an expression's static type exactly matches the given type.
bool isExpressionExactlyType(Expression expression, TypeChecker checker) {
  if (expression.staticType case final type?) {
    return checker.isExactlyType(type);
  }
  return false;
}

/// Checks whether an instance creation uses only the specified named parameter.
///
/// Returns true when the [node] has:
/// - Only one relevant named argument whose name equals [parameter]
/// - The argument value is not a null literal and the argument type is not
///   nullable (i.e. not `T?`)
/// - No other arguments are present, except those explicitly listed in
///   [ignoredParameters]
bool isInstanceCreationExpressionOnlyUsingParameter(
  InstanceCreationExpression node, {
  required String parameter,
  Set<String> ignoredParameters = const {},
}) {
  var hasParameter = false;

  for (final argument in node.argumentList.arguments) {
    if (argument
        case NamedExpression(
          name: Label(label: SimpleIdentifier(name: final argumentName)),
          :final expression,
          :final staticType,
        )) {
      if (ignoredParameters.contains(argumentName)) {
        continue;
      } else if (argumentName == parameter &&
          expression is! NullLiteral &&
          staticType?.nullabilitySuffix != NullabilitySuffix.question) {
        hasParameter = true;
      } else {
        // Other named arguments are not allowed
        return false;
      }
    } else {
      // Other arguments are not allowed
      return false;
    }
  }
  return hasParameter;
}

/// Given a function body, returns the single return expression if there is one.
Expression? maybeGetSingleReturnExpression(FunctionBody body) {
  return switch (body) {
    ExpressionFunctionBody(:final expression) ||
    BlockFunctionBody(block: Block(statements: [ReturnStatement(:final expression?)])) =>
      expression,
    _ => null,
  };
}

/// Extension for Iterable to add firstWhereOrNull.
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
