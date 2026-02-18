import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when `Future<void> Function()` is used instead of `AsyncCallback`.
///
/// The `AsyncCallback` typedef from `package:flutter/foundation.dart` is a
/// cleaner and more readable alternative to the verbose
/// `Future<void> Function()` type annotation.
///
/// ## Example
///
/// ❌ Bad:
/// ```dart
/// void fn(Future<void> Function() callback) {}
/// ```
///
/// ✅ Good:
/// ```dart
/// void fn(AsyncCallback callback) {}
/// ```
class PreferAsyncCallback extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_async_callback',
    "Use 'AsyncCallback' instead of 'Future<void> Function()'.",
    correctionMessage:
        "Replace with 'AsyncCallback' from "
        "'package:flutter/foundation.dart'.",
  );

  PreferAsyncCallback()
    : super(
        name: 'prefer_async_callback',
        description:
            'Warns when Future<void> Function() is used instead of AsyncCallback.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addGenericFunctionType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferAsyncCallback rule;

  _Visitor(this.rule);

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    // Skip typedef definitions (e.g., typedef AsyncCallback = Future<void> Function())
    if (node.parent is GenericTypeAlias) return;

    // Must have no type parameters (no generic function)
    if (node.typeParameters != null) return;

    // Must have no parameters: Function()
    if (node.parameters.parameters.isNotEmpty) return;

    // Return type must be Future<void>
    final returnType = node.returnType;
    if (returnType is! NamedType) return;
    if (returnType.name.lexeme != 'Future') return;

    // Must have exactly one type argument: <void>
    final typeArgs = returnType.typeArguments;
    if (typeArgs == null) return;
    if (typeArgs.arguments.length != 1) return;

    final typeArg = typeArgs.arguments.first;
    if (typeArg is! NamedType) return;
    if (typeArg.name.lexeme != 'void') return;

    rule.reportAtNode(node);
  }
}
