import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when `useMemoized` is used to memoize a function expression.
///
/// `useCallback` is specifically designed for memoizing callbacks and is more
/// semantically correct than wrapping a function in `useMemoized`.
class PreferUseCallback extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_use_callback',
    "Use 'useCallback' instead of 'useMemoized' for memoizing functions.",
    correctionMessage: "Replace 'useMemoized' with 'useCallback'.",
  );

  PreferUseCallback()
    : super(
        name: 'prefer_use_callback',
        description:
            'Warns when useMemoized is used to memoize a function expression.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferUseCallback rule;

  _Visitor(this.rule);

  static final _isUseMemoized = RegExp(r'^_?useMemoized$');

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isUseMemoized.hasMatch(node.methodName.name)) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final factory = args.first;
    if (factory is! FunctionExpression) return;

    // Check if the factory returns a function type
    if (_returnsFunction(factory)) {
      rule.reportAtNode(node);
    }
  }

  /// Returns true if the function expression's body evaluates to a Function
  /// type. This covers:
  /// - `() => () { ... }` (returns a closure)
  /// - `() => (x) => x + 1` (returns a closure)
  /// - `() => myMethod` (returns a tear-off)
  /// - `{ return () { ... }; }` (block body returning a closure)
  static bool _returnsFunction(FunctionExpression factory) {
    final body = factory.body;

    Expression? returnExpression;
    if (body is ExpressionFunctionBody) {
      returnExpression = body.expression;
    } else if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.length == 1 && statements.first is ReturnStatement) {
        returnExpression = (statements.first as ReturnStatement).expression;
      }
    }

    if (returnExpression == null) return false;

    // Check static type of the returned expression
    final returnType = returnExpression.staticType;
    if (returnType == null) return false;

    return returnType is FunctionType;
  }
}
