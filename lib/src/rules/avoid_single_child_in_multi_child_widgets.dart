import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';
import 'package:many_lints/src/utils/helpers.dart';

/// Warns when multi-child widgets have only a single child.
class AvoidSingleChildInMultiChildWidgets extends AnalysisRule {
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
  void registerNodeProcessors(
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

  static const _complain = [
    ('children', TypeChecker.fromName('Column', packageName: 'flutter')),
    ('children', TypeChecker.fromName('Row', packageName: 'flutter')),
    ('children', TypeChecker.fromName('Wrap', packageName: 'flutter')),
    ('children', TypeChecker.fromName('Flex', packageName: 'flutter')),
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
      '',
      TypeChecker.fromName('SliverChildListDelegate', packageName: 'flutter'),
    ),
  ];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName.type;
    if (constructorName.element case final typeElement?) {
      // is it something we want to complain about?
      final match = _complain.firstWhereOrNull(
        (e) => e.$2.isExactly(typeElement),
      );
      if (match == null) return;

      // does it have a children argument?
      Expression? children;

      if (match.$1.isEmpty) {
        // handle positional (first argument)
        if (node.argumentList.arguments.isNotEmpty) {
          children = node.argumentList.arguments.first;
        }
      } else {
        // handle named argument
        for (final arg in node.argumentList.arguments) {
          if (arg is NamedExpression && arg.name.label.name == match.$1) {
            children = arg.expression;
            break;
          }
        }
      }

      if (children == null) return;

      _checkInstanceCreation(constructorName, children);
    }
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
      };
    }

    return checkExpression(list.elements.first);
  }
}
