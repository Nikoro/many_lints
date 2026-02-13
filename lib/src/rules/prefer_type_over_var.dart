import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a variable is declared with the `var` keyword instead of an
/// explicit type.
///
/// Although `var` is shorter to write, the use of this keyword makes it
/// difficult to understand the type of the declared variable, especially
/// when the initializer is complex or not immediately visible.
///
/// ## Example
///
/// ❌ Bad:
/// ```dart
/// class SomeClass {
///   void method() {
///     var variable = nullableMethod();
///   }
/// }
///
/// var topLevelVariable = nullableMethod();
///
/// String? nullableMethod() => null;
/// ```
///
/// ✅ Good:
/// ```dart
/// class SomeClass {
///   void method() {
///     String? variable = nullableMethod();
///   }
/// }
///
/// String? topLevelVariable = nullableMethod();
///
/// String? nullableMethod() => null;
/// ```
class PreferTypeOverVar extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_type_over_var',
    "Prefer an explicit type annotation over 'var'.",
    correctionMessage: 'Try replacing var with an explicit type annotation.',
  );

  PreferTypeOverVar()
    : super(
        name: 'prefer_type_over_var',
        description:
            'Warns when a variable is declared with the var keyword instead of a type.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addVariableDeclarationStatement(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
    registry.addForStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferTypeOverVar rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _checkVariableDeclarationList(node.variables);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _checkVariableDeclarationList(node.variables);
  }

  @override
  void visitForStatement(ForStatement node) {
    // Check for-loop variable declarations
    final forParts = node.forLoopParts;
    if (forParts is ForPartsWithDeclarations) {
      _checkVariableDeclarationList(forParts.variables);
    }
  }

  void _checkVariableDeclarationList(VariableDeclarationList variables) {
    // Check if the keyword is 'var'
    final keyword = variables.keyword;
    if (keyword == null) return;
    if (keyword.lexeme != 'var') return;

    // Report at the var keyword
    rule.reportAtToken(keyword);
  }
}
