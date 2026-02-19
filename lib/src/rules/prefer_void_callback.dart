import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when `void Function()` is used instead of `VoidCallback`.
///
/// The `VoidCallback` typedef from `dart:ui` is a cleaner and more readable
/// alternative to the verbose `void Function()` type annotation.
///
/// ## Example
///
/// ❌ Bad:
/// ```dart
/// void fn(void Function() callback) {}
/// ```
///
/// ✅ Good:
/// ```dart
/// void fn(VoidCallback callback) {}
/// ```
class PreferVoidCallback extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_void_callback',
    "Use 'VoidCallback' instead of 'void Function()'.",
    correctionMessage: "Replace with 'VoidCallback' from 'dart:ui'.",
  );

  PreferVoidCallback()
    : super(
        name: 'prefer_void_callback',
        description:
            'Warns when void Function() is used instead of VoidCallback.',
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
  final PreferVoidCallback rule;

  _Visitor(this.rule);

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    // Skip typedef definitions (e.g., typedef VoidCallback = void Function())
    if (node.parent is GenericTypeAlias) return;

    // Must have no type parameters (no generic function)
    if (node.typeParameters != null) return;

    // Must have no parameters: Function()
    if (node.parameters.parameters.isNotEmpty) return;

    // Return type must be void
    final returnType = node.returnType;
    if (returnType is! NamedType) return;
    if (returnType.name.lexeme != 'void') return;

    rule.reportAtNode(node);
  }
}
