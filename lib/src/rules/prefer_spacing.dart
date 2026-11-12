import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../flutter_type_checkers.dart';
import '../flutter_widget_helpers.dart';
import '../many_lints_rule.dart';

class PreferSpacing extends ManyLintsRule {
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
  final PreferSpacing rule;

  _Visitor(this.rule);

  static const _smallestListWithOneSpacer = 3;

  static const _flexWidgets = [
    (columnChecker, FlexAxis.vertical),
    (rowChecker, FlexAxis.horizontal),
    (flexChecker, null),
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

    // Edge case: `Row(...)` can reach the AST as a method invocation.
    _checkFlexWidget(node.staticType, node.argumentList);
  }

  void _checkFlexWidget(DartType? staticType, ArgumentList argumentList) {
    if (staticType == null) return;

    final match = _flexWidgets.firstWhereOrNull(
      (e) => e.$1.isExactlyType(staticType),
    );
    if (match == null) return;

    final hasSpacingArg = argumentList.arguments.whereType<NamedArgument>().any(
      (arg) => arg.name.lexeme == 'spacing',
    );
    if (hasSpacingArg) return;

    final childrenExpr = namedArgumentValue(argumentList.arguments, 'children');
    if (childrenExpr == null) return;

    if (childrenExpr is ListLiteral) {
      _checkUniformSpacersInList(childrenExpr, match.$2);
    }
  }

  void _checkUniformSpacersInList(ListLiteral list, FlexAxis? parentAxis) {
    final elements = list.elements;
    final minChildren = rule.config.intOption(
      'min_children',
      defaultValue: _smallestListWithOneSpacer,
    );
    if (elements.length < minChildren) return;

    final sizedBoxes = <Expression>[];
    String? uniformValue;
    bool isUniform = true;

    for (final element in elements) {
      if (element is! Expression) continue;

      final spacer = _sizedBoxSpacer(element);
      if (spacer == null) continue;

      if (parentAxis == FlexAxis.vertical && spacer.dimension != 'height') {
        continue;
      }
      if (parentAxis == FlexAxis.horizontal && spacer.dimension != 'width') {
        continue;
      }

      sizedBoxes.add(element);

      final value = spacer.value;
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

  void _checkSeparatedBy(MethodInvocation node) {
    if (!_isChildrenOfFlexWidget(node)) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final separatorArg = args.first;
    if (separatorArg is! Expression) return;
    if (_sizedBoxSpacer(separatorArg) == null) return;

    rule.reportAtNode(node);
  }

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

  bool _isChildrenOfFlexWidget(Expression node) {
    AstNode topOfChain = node;
    for (
      var parent = node.parent;
      parent is MethodInvocation && parent.target == topOfChain;
      parent = parent.parent
    ) {
      topOfChain = parent;
    }

    final namedArg = topOfChain.parent;
    if (namedArg is! NamedArgument) return false;
    if (namedArg.name.lexeme != 'children') return false;

    final argList = namedArg.parent;
    if (argList is! ArgumentList) return false;

    final parentExpr = argList.parent;

    final parentArgs = switch (parentExpr) {
      InstanceCreationExpression() => parentExpr.argumentList.arguments,
      MethodInvocation() => parentExpr.argumentList.arguments,
      _ => null,
    };
    if (parentArgs == null) return false;

    final hasSpacingArg = parentArgs.whereType<NamedArgument>().any(
      (arg) => arg.name.lexeme == 'spacing',
    );
    if (hasSpacingArg) return false;

    final parentType = switch (parentExpr) {
      InstanceCreationExpression() => parentExpr.staticType,
      MethodInvocation() => parentExpr.staticType,
      _ => null,
    };
    if (parentType == null) return false;

    return _flexWidgets.any((e) => e.$1.isExactlyType(parentType));
  }

  static _Spacer? _sizedBoxSpacer(Expression expr) {
    final arguments = switch (expr) {
      InstanceCreationExpression(:final argumentList) => argumentList,
      MethodInvocation(:final argumentList) => argumentList,
      _ => null,
    };
    if (arguments == null) return null;
    if (!isExpressionExactlyType(expr, sizedBoxChecker)) return null;
    return _spacerFromArguments(arguments.arguments);
  }

  static _Spacer? _spacerFromArguments(NodeList<Argument> args) {
    String? spacingParam;
    String? spacingValue;

    for (final arg in args) {
      if (arg case NamedArgument(
        name: Token(lexeme: final name),
        :final argumentExpression,
      )) {
        if (name == 'key') continue;
        if ((name == 'height' || name == 'width') && spacingParam == null) {
          spacingParam = name;
          spacingValue = argumentExpression.toSource();
        } else {
          return null;
        }
      } else {
        return null;
      }
    }

    if (spacingParam == null || spacingValue == null) return null;
    return (dimension: spacingParam, value: spacingValue);
  }
}

typedef _Spacer = ({String dimension, String value});

class _SizedBoxYieldFinder extends RecursiveAstVisitor<void> {
  bool foundSizedBoxYield = false;

  @override
  void visitYieldStatement(YieldStatement node) {
    final expr = node.expression;
    if (_Visitor._sizedBoxSpacer(expr) != null) {
      foundSizedBoxYield = true;
    }
    super.visitYieldStatement(node);
  }

  // Edge case: a nested closure yields into its own generator, not the expand callback.
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
