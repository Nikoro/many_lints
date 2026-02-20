import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `Expanded` wraps an empty `SizedBox` or `Container` instead of
/// using the dedicated `Spacer` widget.
class AvoidExpandedAsSpacer extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_expanded_as_spacer',
    "Prefer replacing Expanded with an empty child with 'Spacer'.",
    correctionMessage: 'Replace with Spacer widget.',
  );

  AvoidExpandedAsSpacer()
    : super(
        name: 'avoid_expanded_as_spacer',
        description:
            'Warns when Expanded wraps an empty SizedBox or Container instead of using Spacer.',
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
  final AvoidExpandedAsSpacer rule;

  _Visitor(this.rule);

  static const _expandedChecker = TypeChecker.fromName(
    'Expanded',
    packageName: 'flutter',
  );

  static const _sizedBoxChecker = TypeChecker.fromName(
    'SizedBox',
    packageName: 'flutter',
  );

  static const _containerChecker = TypeChecker.fromName(
    'Container',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node.staticType, node.argumentList, node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node.staticType, node.argumentList, node);
  }

  void _check(
    DartType? staticType,
    ArgumentList argumentList,
    Expression node,
  ) {
    if (staticType == null || !_expandedChecker.isExactlyType(staticType)) {
      return;
    }

    final arguments = argumentList.arguments;

    // Find the child argument
    Expression? childExpr;
    for (final arg in arguments.whereType<NamedExpression>()) {
      if (arg.name.label.name == 'child') {
        childExpr = arg.expression;
        break;
      }
    }

    if (childExpr == null) return;

    if (_isEmptyWidget(childExpr)) {
      rule.reportAtNode(node);
    }
  }

  /// Returns true if the expression is an empty SizedBox() or Container() —
  /// i.e. has no arguments or only a `key` argument.
  bool _isEmptyWidget(Expression expr) {
    final type = expr.staticType;
    if (type == null) return false;

    final isSizedBox = _sizedBoxChecker.isExactlyType(type);
    final isContainer = _containerChecker.isExactlyType(type);
    if (!isSizedBox && !isContainer) return false;

    final ArgumentList argumentList;
    if (expr is InstanceCreationExpression) {
      argumentList = expr.argumentList;
    } else if (expr is MethodInvocation) {
      argumentList = expr.argumentList;
    } else {
      return false;
    }

    for (final arg in argumentList.arguments) {
      if (arg is NamedExpression) {
        if (arg.name.label.name != 'key') return false;
      } else {
        return false;
      }
    }

    return true;
  }
}
