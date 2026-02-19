import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';
import 'package:many_lints/src/flutter_widget_helpers.dart';
import 'package:many_lints/src/type_checker.dart';

/// Warns when SizedBox or Padding is used for spacing inside multi-child
/// widgets. Suggests using the Gap widget instead.
class UseGap extends AnalysisRule {
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
  void registerNodeProcessors(
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

  static const _sizedBoxChecker = TypeChecker.fromName(
    'SizedBox',
    packageName: 'flutter',
  );

  static const _paddingChecker = TypeChecker.fromName(
    'Padding',
    packageName: 'flutter',
  );

  static const _multiChildWidgets = [
    (TypeChecker.fromName('Column', packageName: 'flutter'), FlexAxis.vertical),
    (TypeChecker.fromName('Row', packageName: 'flutter'), FlexAxis.horizontal),
    (TypeChecker.fromName('Wrap', packageName: 'flutter'), null),
    (TypeChecker.fromName('Flex', packageName: 'flutter'), null),
    (
      TypeChecker.fromName('ListView', packageName: 'flutter'),
      FlexAxis.vertical,
    ),
  ];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (isExpressionExactlyType(node, _sizedBoxChecker)) {
      _checkSizedBox(node);
    } else if (isExpressionExactlyType(node, _paddingChecker)) {
      _checkPadding(node);
    }
  }

  void _checkSizedBox(InstanceCreationExpression node) {
    // Must have only height or width (+ optional key), not both, not child
    final args = node.argumentList.arguments;
    String? spacingParam;

    for (final arg in args) {
      if (arg case NamedExpression(
        name: Label(label: SimpleIdentifier(name: final name)),
      )) {
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
    final paddingArg = node.argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'padding');

    if (paddingArg == null) return;

    final paddingExpr = paddingArg.expression;

    // Check for EdgeInsets.only(...)
    if (paddingExpr is! InstanceCreationExpression) return;
    final constructorName = paddingExpr.constructorName;
    if (constructorName.name?.name != 'only') return;

    // Check it's EdgeInsets type
    final typeName = constructorName.type.name.lexeme;
    if (typeName != 'EdgeInsets' && typeName != 'EdgeInsetsDirectional') return;

    // Must have exactly one directional argument
    final dirArgs = paddingExpr.argumentList.arguments
        .whereType<NamedExpression>()
        .where((e) => e.name.label.name != 'key')
        .toList();

    if (dirArgs.length != 1) return;

    final dirName = dirArgs.first.name.label.name;
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
    current = listLiteral.parent;

    // The ListLiteral should be the expression of a NamedExpression named 'children'
    if (current case NamedExpression(
      name: Label(label: SimpleIdentifier(name: 'children')),
    )) {
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
