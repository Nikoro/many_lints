import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ast_node_analysis.dart';
import '../flutter_type_checkers.dart';
import '../type_checker.dart';

class AvoidSingleChildInMultiChildWidgets extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_single_child_in_multi_child_widgets',
    'Avoid using {0} with a single child.',
    correctionMessage:
        'Remove the {0} and achieve the same result using dedicated widgets.',
  );

  AvoidSingleChildInMultiChildWidgets()
    : super(
        name: 'avoid_single_child_in_multi_child_widgets',
        description: 'Warns when multi-child widgets have only a single child.',
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
  final AvoidSingleChildInMultiChildWidgets rule;

  _Visitor(this.rule);

  static const _positionalParameter = '';

  static const _childListParameters = [
    ('children', columnChecker),
    ('children', rowChecker),
    ('children', wrapChecker),
    ('children', flexChecker),
    ('children', TypeChecker.fromName('SliverList', packageName: 'flutter')),
    (
      'slivers',
      TypeChecker.fromName('SliverMainAxisGroup', packageName: 'flutter'),
    ),
    (
      'slivers',
      TypeChecker.fromName('SliverCrossAxisGroup', packageName: 'flutter'),
    ),
    (
      'children',
      TypeChecker.fromName('MultiSliver', packageName: 'sliver_tools'),
    ),
    (
      _positionalParameter,
      TypeChecker.fromName('SliverChildListDelegate', packageName: 'flutter'),
    ),
  ];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName.type;
    if (constructorName.element case final typeElement?) {
      final match = _childListParameters.firstWhereOrNull(
        (e) => e.$2.isExactly(typeElement),
      );
      if (match == null) return;

      final children = _childListArgument(node.argumentList, match.$1);
      if (children == null) return;

      _checkInstanceCreation(constructorName, children);
    }
  }

  Expression? _childListArgument(
    ArgumentList argumentList,
    String parameterName,
  ) {
    final arguments = argumentList.arguments;
    if (parameterName == _positionalParameter) {
      return switch (arguments.firstOrNull) {
        final Expression first => first,
        _ => null,
      };
    }
    for (final arg in arguments) {
      if (arg is NamedArgument && arg.name.lexeme == parameterName) {
        return arg.argumentExpression;
      }
    }
    return null;
  }

  void _checkInstanceCreation(NamedType constructorName, Expression children) {
    if (children case final ListLiteral list) {
      if (_hasSingleElement(list)) {
        rule.reportAtNode(
          constructorName,
          arguments: [constructorName.name.lexeme],
        );
      }
    }
  }

  bool _hasSingleElement(ListLiteral list) {
    if (list.elements.length != 1) return false;

    bool checkExpression(CollectionElement expression) {
      return switch (expression) {
        Expression() => true,
        ForElement() || MapLiteralEntry() || SpreadElement() => false,
        IfElement(:final thenElement, :final elseElement) =>
          checkExpression(thenElement) &&
              (elseElement == null || checkExpression(elseElement)),
        NullAwareElement(:final value) => checkExpression(value),
        _ => false,
      };
    }

    return checkExpression(list.elements.first);
  }
}
