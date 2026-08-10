import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../flutter_type_checkers.dart';
import '../flutter_widget_helpers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when SizedBox or Padding is used for spacing inside multi-child
/// widgets. Suggests using the Gap widget instead.
class UseGap extends ManyLintsRule {
  static const LintCode code = LintCode(
    'use_gap',
    'Use Gap widget instead of {0} for spacing in multi-child widgets.',
    correctionMessage: 'Replace with Gap widget from the gap package.',
  );

  UseGap()
    : super(
        name: 'use_gap',
        description: 'Prefer Gap widget over SizedBox or Padding for spacing.',
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
  final UseGap rule;

  _Visitor(this.rule);

  static const _multiChildWidgets = [
    (columnChecker, FlexAxis.vertical),
    (rowChecker, FlexAxis.horizontal),
    (wrapChecker, null),
    (flexChecker, null),
    (
      TypeChecker.fromName('ListView', packageName: 'flutter'),
      FlexAxis.vertical,
    ),
  ];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (isExpressionExactlyType(node, sizedBoxChecker)) {
      _checkSizedBox(node);
    } else if (isExpressionExactlyType(node, paddingChecker)) {
      _checkPadding(node);
    }
  }

  void _checkSizedBox(InstanceCreationExpression node) {
    // Must have only height or width (+ optional key), not both, not child
    final args = node.argumentList.arguments;
    String? spacingParam;

    for (final arg in args) {
      if (arg case NamedArgument(name: Token(lexeme: final name))) {
        if (name == 'key') continue;
        if (name == 'height' && spacingParam == null) {
          spacingParam = 'height';
        } else if (name == 'width' && spacingParam == null) {
          spacingParam = 'width';
        } else {
          return; // has child, both height+width, or other params
        }
      } else {
        return; // positional args not expected
      }
    }

    if (spacingParam == null) return;

    final parentAxis = _findParentMultiChildAxis(node);
    if (parentAxis == null) return;

    // Verify axis match: height for vertical, width for horizontal
    final axis = parentAxis.$1;
    if (axis != null) {
      if (axis == FlexAxis.vertical && spacingParam != 'height') return;
      if (axis == FlexAxis.horizontal && spacingParam != 'width') return;
    }

    rule.reportAtNode(node.constructorName, arguments: ['SizedBox']);
  }

  void _checkPadding(InstanceCreationExpression node) {
    // Must have padding param with EdgeInsets.only with a single direction
    final paddingExpr = namedArgumentValue(
      node.argumentList.arguments,
      'padding',
    );
    if (paddingExpr == null) return;

    // Check for EdgeInsets.only(...)
    if (paddingExpr is! InstanceCreationExpression) return;
    final constructorName = paddingExpr.constructorName;
    if (constructorName.name?.name != 'only') return;

    // Check it's EdgeInsets type
    final typeName = constructorName.type.name.lexeme;
    if (typeName != 'EdgeInsets' && typeName != 'EdgeInsetsDirectional') return;

    // Must have exactly one directional argument
    final dirArgs = paddingExpr.argumentList.arguments
        .whereType<NamedArgument>()
        .where((e) => e.name.lexeme != 'key')
        .toList();

    if (dirArgs.length != 1) return;

    final dirName = dirArgs.first.name.lexeme;
    final verticalDirs = {'top', 'bottom'};
    final horizontalDirs = {'left', 'right', 'start', 'end'};

    if (!verticalDirs.contains(dirName) && !horizontalDirs.contains(dirName)) {
      return;
    }

    final parentAxis = _findParentMultiChildAxis(node);
    if (parentAxis == null) return;

    // Verify axis match
    final axis = parentAxis.$1;
    if (axis != null) {
      if (axis == FlexAxis.vertical && !verticalDirs.contains(dirName)) return;
      if (axis == FlexAxis.horizontal && !horizontalDirs.contains(dirName)) {
        return;
      }
    }

    rule.reportAtNode(node.constructorName, arguments: ['Padding']);
  }

  /// Walks up the AST to find if this node is inside the `children` list
  /// of a multi-child widget. Returns the axis if found, null otherwise.
  (FlexAxis?,)? _findParentMultiChildAxis(InstanceCreationExpression node) {
    // Walk up: node → ListLiteral → NamedExpression(children) → ArgumentList → InstanceCreation
    var current = node.parent;

    // The node should be directly inside a ListLiteral
    if (current is! ListLiteral) return null;

    final listLiteral = current;

    // `min_children` skips short lists, where a single spacer reads fine
    // inline. Default 1 reports every list, reproducing the previous
    // behaviour; `prefer_spacing` exposes the same key.
    if (listLiteral.elements.length <
        rule.config.intOption('min_children', defaultValue: 1)) {
      return null;
    }

    current = listLiteral.parent;

    // The ListLiteral should be the value of a NamedArgument named 'children'
    if (current case NamedArgument(name: Token(lexeme: 'children'))) {
      current = current.parent;
    } else {
      return null;
    }

    // Should be inside an ArgumentList
    if (current is! ArgumentList) return null;
    current = current.parent;

    // Should be an InstanceCreationExpression of a multi-child widget
    if (current is! InstanceCreationExpression) return null;

    final parentType = current.constructorName.type;
    if (parentType.element case final typeElement?) {
      for (final (checker, axis) in _multiChildWidgets) {
        if (checker.isExactly(typeElement)) {
          return (axis,);
        }
      }
    }

    return null;
  }
}
