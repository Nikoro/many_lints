import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

class AvoidFlexibleOutsideFlex extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorType = node.constructorName.type;
    final element = constructorType.element;
    if (element == null) return;

    if (!_flexibleChecker.isSuperOf(element)) return;

    if (_isDirectChildOfFlex(node)) return;

    final widgetName = constructorType.name.lexeme;
    rule.reportAtNode(node.constructorName, arguments: [widgetName]);
  }

  static bool _isDirectChildOfFlex(InstanceCreationExpression node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ListLiteral) {
        current = current.parent;
        continue;
      }

      if (current is NamedArgument) {
        current = current.parent;
        continue;
      }

      if (current is ArgumentList) {
        final parent = current.parent;
        if (parent is InstanceCreationExpression) {
          final parentElement = parent.constructorName.type.element;
          if (parentElement != null &&
              anyFlexChecker.isSuperOf(parentElement)) {
            return true;
          }
        }
        return false;
      }

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
