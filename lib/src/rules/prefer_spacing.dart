import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';
import 'package:many_lints/src/flutter_widget_helpers.dart';
import 'package:many_lints/src/type_checker.dart';

/// Warns when SizedBox widgets are used for spacing inside Row, Column, or Flex
/// children instead of using the `spacing` argument (Flutter 3.27+).
///
/// Detects three patterns:
/// 1. Direct SizedBox in children list with uniform spacing
/// 2. `.separatedBy()` with SizedBox
/// 3. `.expand()` with generator yielding SizedBox
class PreferSpacing extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_spacing',
    "Prefer passing the 'spacing' argument instead of using SizedBox.",
    correctionMessage:
        "Use the 'spacing' argument on Row, Column, or Flex instead.",
  );

  PreferSpacing()
    : super(
        name: 'prefer_spacing',
        description:
            "Prefer the 'spacing' argument over SizedBox for spacing in "
            'Row, Column, and Flex.',
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
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSpacing rule;

  _Visitor(this.rule);

  static const _sizedBoxChecker = TypeChecker.fromName(
    'SizedBox',
    packageName: 'flutter',
  );

  static const _flexWidgets = [
    (TypeChecker.fromName('Column', packageName: 'flutter'), FlexAxis.vertical),
    (TypeChecker.fromName('Row', packageName: 'flutter'), FlexAxis.horizontal),
    (TypeChecker.fromName('Flex', packageName: 'flutter'), null),
  ];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _checkFlexWidget(node.staticType, node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    if (methodName == 'separatedBy') {
      _checkSeparatedBy(node);
      return;
    }
    if (methodName == 'expand') {
      _checkExpand(node);
      return;
    }

    // Handle flex widget constructor calls parsed as MethodInvocation
    _checkFlexWidget(node.staticType, node.argumentList);
  }

  /// Checks a flex widget (Row/Column/Flex) for SizedBox spacers in children.
  void _checkFlexWidget(DartType? staticType, ArgumentList argumentList) {
    if (staticType == null) return;

    final match = _flexWidgets.firstWhereOrNull(
      (e) => e.$1.isExactlyType(staticType),
    );
    if (match == null) return;

    // Check that the widget doesn't already have a spacing argument
    final hasSpacingArg = argumentList.arguments
        .whereType<NamedExpression>()
        .any((arg) => arg.name.label.name == 'spacing');
    if (hasSpacingArg) return;

    // Find the children argument
    final childrenArg = argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((arg) => arg.name.label.name == 'children');
    if (childrenArg == null) return;

    final childrenExpr = childrenArg.expression;

    // Pattern 1: Direct list literal with SizedBox spacers
    if (childrenExpr is ListLiteral) {
      _checkDirectSizedBoxInList(childrenExpr, match.$2);
    }
  }

  /// Pattern 1: Direct SizedBox widgets used as spacers in a children list.
  /// Only triggers when all SizedBox spacers have the same value (uniform).
  void _checkDirectSizedBoxInList(ListLiteral list, FlexAxis? parentAxis) {
    final elements = list.elements;
    if (elements.length < 3) return;

    // Collect all SizedBox spacers and their values
    final sizedBoxes = <Expression>[];
    String? uniformValue;
    bool isUniform = true;

    for (final element in elements) {
      if (element is! Expression) continue;

      final spacingInfo = _extractSizedBoxSpacingFromExpr(element);
      if (spacingInfo == null) continue;

      // Check axis match
      if (parentAxis != null) {
        if (parentAxis == FlexAxis.vertical && spacingInfo.$1 != 'height') {
          continue;
        }
        if (parentAxis == FlexAxis.horizontal && spacingInfo.$1 != 'width') {
          continue;
        }
      }

      sizedBoxes.add(element);

      final value = spacingInfo.$2;
      if (uniformValue == null) {
        uniformValue = value;
      } else if (uniformValue != value) {
        isUniform = false;
      }
    }

    if (sizedBoxes.isEmpty || !isUniform) return;

    for (final sizedBox in sizedBoxes) {
      rule.reportAtNode(sizedBox);
    }
  }

  /// Pattern 2: `.separatedBy(SizedBox(...))` on a list used as children.
  void _checkSeparatedBy(MethodInvocation node) {
    if (!_isChildrenOfFlexWidget(node)) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final separatorArg = args.first;
    if (_extractSizedBoxSpacingFromExpr(separatorArg) == null) return;

    rule.reportAtNode(node);
  }

  /// Pattern 3: `.expand((w) sync* { yield SizedBox(...); yield w; })`
  void _checkExpand(MethodInvocation node) {
    if (!_isChildrenOfFlexWidget(node)) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final callback = args.first;
    if (callback is! FunctionExpression) return;

    final body = callback.body;
    if (body is! BlockFunctionBody) return;

    final finder = _SizedBoxYieldFinder();
    body.visitChildren(finder);

    if (finder.foundSizedBoxYield) {
      rule.reportAtNode(node);
    }
  }

  /// Checks if a node is used as the `children` argument of a Row/Column/Flex.
  bool _isChildrenOfFlexWidget(Expression node) {
    // Walk up through chained method calls like .skip(1).toList()
    // where our node is the target (receiver) of subsequent calls
    AstNode topOfChain = node;
    while (topOfChain.parent is MethodInvocation) {
      final parent = topOfChain.parent! as MethodInvocation;
      if (parent.target != topOfChain) break;
      topOfChain = parent;
    }

    // Should be a NamedExpression(children: ...)
    final namedExpr = topOfChain.parent;
    if (namedExpr is! NamedExpression) return false;
    if (namedExpr.name.label.name != 'children') return false;

    final argList = namedExpr.parent;
    if (argList is! ArgumentList) return false;

    final parentExpr = argList.parent;

    // Check parent doesn't already have spacing arg
    final parentArgs = switch (parentExpr) {
      InstanceCreationExpression() => parentExpr.argumentList.arguments,
      MethodInvocation() => parentExpr.argumentList.arguments,
      _ => null,
    };
    if (parentArgs == null) return false;

    final hasSpacingArg = parentArgs.whereType<NamedExpression>().any(
      (arg) => arg.name.label.name == 'spacing',
    );
    if (hasSpacingArg) return false;

    // Check if parent is a flex widget
    final parentType = switch (parentExpr) {
      InstanceCreationExpression() => parentExpr.staticType,
      MethodInvocation() => parentExpr.staticType,
      _ => null,
    };
    if (parentType == null) return false;

    return _flexWidgets.any((e) => e.$1.isExactlyType(parentType));
  }

  /// Extracts spacing info from an expression that might be a SizedBox.
  /// Handles both InstanceCreationExpression and MethodInvocation forms.
  /// Returns (paramName, valueSource) or null.
  static (String, String)? _extractSizedBoxSpacingFromExpr(Expression expr) {
    if (expr is InstanceCreationExpression) {
      if (!isExpressionExactlyType(expr, _sizedBoxChecker)) return null;
      return _extractSizedBoxSpacing(expr.argumentList.arguments);
    }
    if (expr is MethodInvocation) {
      if (!isExpressionExactlyType(expr, _sizedBoxChecker)) return null;
      return _extractSizedBoxSpacing(expr.argumentList.arguments);
    }
    return null;
  }

  /// Extracts spacing info from SizedBox arguments.
  /// Returns (paramName, valueSource) or null if not a pure spacer.
  static (String, String)? _extractSizedBoxSpacing(NodeList<Expression> args) {
    String? spacingParam;
    String? spacingValue;

    for (final arg in args) {
      if (arg case NamedExpression(
        name: Label(label: SimpleIdentifier(name: final name)),
      )) {
        if (name == 'key') continue;
        if ((name == 'height' || name == 'width') && spacingParam == null) {
          spacingParam = name;
          spacingValue = arg.expression.toSource();
        } else {
          return null; // has child, both dimensions, or other params
        }
      } else {
        return null; // positional args not expected
      }
    }

    if (spacingParam == null || spacingValue == null) return null;
    return (spacingParam, spacingValue);
  }
}

/// Recursively searches for `yield SizedBox(...)` expressions.
class _SizedBoxYieldFinder extends RecursiveAstVisitor<void> {
  bool foundSizedBoxYield = false;

  @override
  void visitYieldStatement(YieldStatement node) {
    final expr = node.expression;
    if (_Visitor._extractSizedBoxSpacingFromExpr(expr) != null) {
      foundSizedBoxYield = true;
    }
    super.visitYieldStatement(node);
  }

  // Stop at nested function boundaries
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
