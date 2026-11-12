import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_inference.dart';

class PreferIterableOf extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_iterable_of',
    'Use {0}.of() instead of {0}.from().',
    correctionMessage:
        'Replace .from() with .of() for compile-time type '
        'safety.',
  );

  PreferIterableOf()
    : super(
        name: 'prefer_iterable_of',
        description:
            'Prefer List.of() / Set.of() over List.from() / Set.from() when '
            'types are already compatible.',
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
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferIterableOf rule;

  _Visitor(this.rule);

  static const _targetNames = {'List', 'Set'};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final name = constructorName.name;
    if (name == null || name.name != 'from') return;

    final typeName = constructorName.type.name.lexeme;
    if (!_targetNames.contains(typeName)) return;

    _check(node, node.argumentList, node.staticType, typeName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'from') return;

    final target = node.target;
    if (target is! SimpleIdentifier) return;
    if (!_targetNames.contains(target.name)) return;

    _check(node, node.argumentList, node.staticType, target.name);
  }

  void _check(
    AstNode node,
    ArgumentList argumentList,
    DartType? resultType,
    String typeName,
  ) {
    final positionalArgs = argumentList.arguments
        .whereType<Expression>()
        .toList();
    if (positionalArgs.length != 1) return;

    final sourceArg = positionalArgs.first;

    if (resultType is! InterfaceType) return;

    final targetTypeArgs = resultType.typeArguments;
    if (targetTypeArgs.isEmpty) return;
    final targetElementType = targetTypeArgs.first;

    final fromAndOfAreEquivalent = targetElementType is DynamicType;
    if (fromAndOfAreEquivalent) {
      rule.reportAtNode(node, arguments: [typeName]);
      return;
    }

    final sourceType = sourceArg.staticType;
    if (sourceType is! InterfaceType) return;

    final sourceElementType = iterableElementType(sourceType);
    if (sourceElementType == null) return;

    if (_isAssignable(sourceElementType, targetElementType)) {
      rule.reportAtNode(node, arguments: [typeName]);
    }
  }

  bool _isAssignable(DartType source, DartType target) {
    if (source is DynamicType) return true;
    if (source == target) return true;

    if (source is InterfaceType && target is InterfaceType) {
      final sourceElement = source.element;
      final targetElement = target.element;

      if (sourceElement == targetElement) return true;

      for (final supertype in sourceElement.allSupertypes) {
        if (supertype.element == targetElement) return true;
      }
    }

    return false;
  }
}
