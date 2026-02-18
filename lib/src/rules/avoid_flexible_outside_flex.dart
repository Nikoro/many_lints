import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';

/// Warns when a Flexible or Expanded widget is used outside a Flex widget.
///
/// Flexible and Expanded widgets should only be used as direct children of
/// Row, Column, or Flex widgets. Using them elsewhere has no effect and
/// indicates a structural issue in the widget tree.
class AvoidFlexibleOutsideFlex extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_flexible_outside_flex',
    '{0} should only be used as a direct child of Row, Column, or Flex.',
    correctionMessage:
        'Move {0} inside a Row, Column, or Flex, or remove the wrapper.',
  );

  AvoidFlexibleOutsideFlex()
    : super(
        name: 'avoid_flexible_outside_flex',
        description:
            'Warns when a Flexible or Expanded widget is used outside '
            'a Flex widget.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidFlexibleOutsideFlex rule;

  _Visitor(this.rule);

  static const _flexibleChecker = TypeChecker.any([
    TypeChecker.fromName('Flexible', packageName: 'flutter'),
    TypeChecker.fromName('Expanded', packageName: 'flutter'),
  ]);

  static const _flexChecker = TypeChecker.any([
    TypeChecker.fromName('Row', packageName: 'flutter'),
    TypeChecker.fromName('Column', packageName: 'flutter'),
    TypeChecker.fromName('Flex', packageName: 'flutter'),
  ]);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorType = node.constructorName.type;
    final element = constructorType.element;
    if (element == null) return;

    // Only interested in Flexible / Expanded
    if (!_flexibleChecker.isSuperOf(element)) return;

    // Walk up the AST to find the nearest parent InstanceCreationExpression
    // that represents a widget constructor. If it's a Flex widget, this is
    // valid. If not (or if there is no parent widget), report the lint.
    if (_isDirectChildOfFlex(node)) return;

    final widgetName = constructorType.name.lexeme;
    rule.reportAtNode(node.constructorName, arguments: [widgetName]);
  }

  /// Checks if [node] is a direct child in a Flex widget's children list
  /// or child parameter.
  static bool _isDirectChildOfFlex(InstanceCreationExpression node) {
    // Walk up the AST parent chain looking for the nearest
    // InstanceCreationExpression that this Flexible/Expanded is an argument of.
    AstNode? current = node.parent;
    while (current != null) {
      // Skip list literals (children: [Flexible(...)])
      if (current is ListLiteral) {
        current = current.parent;
        continue;
      }

      // Skip named expressions (child: Flexible(...) or children: [...])
      if (current is NamedExpression) {
        current = current.parent;
        continue;
      }

      // We've reached an argument list — check the parent constructor
      if (current is ArgumentList) {
        final parent = current.parent;
        if (parent is InstanceCreationExpression) {
          final parentElement = parent.constructorName.type.element;
          if (parentElement != null && _flexChecker.isSuperOf(parentElement)) {
            return true;
          }
        }
        return false;
      }

      // Stop at function/method boundaries — we've left the widget tree
      if (current is FunctionExpression ||
          current is FunctionDeclaration ||
          current is MethodDeclaration) {
        return false;
      }

      current = current.parent;
    }
    return false;
  }
}
