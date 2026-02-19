import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';
import 'package:many_lints/src/type_checker.dart';

/// Warns when a sequence of nested widgets could be replaced with a single
/// `Container` widget.
///
/// `Container` internally combines `Align`, `Padding`, `DecoratedBox`,
/// `ConstrainedBox`, `Transform`, `ClipPath`, `ColoredBox`, and `SizedBox`
/// widgets. When 3+ of these widgets are nested, they can be collapsed into
/// a single `Container`.
class PreferContainer extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_container',
    'This sequence of {0} nested widgets can be replaced with a single '
        'Container widget.',
    correctionMessage:
        'Try using a Container widget with the appropriate '
        'parameters instead of nesting multiple widgets.',
  );

  PreferContainer()
    : super(
        name: 'prefer_container',
        description:
            'Prefer Container over sequences of nested widgets that '
            'Container already combines internally.',
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

/// Maps a widget type name to the Container parameter it corresponds to.
///
/// Returns `null` if the widget is not a Container-compatible widget.
String? _containerParamForWidget(String widgetName) {
  return switch (widgetName) {
    'Padding' => 'padding',
    'Align' => 'alignment',
    'Center' => 'alignment',
    'ColoredBox' => 'color',
    'DecoratedBox' => 'decoration',
    'ConstrainedBox' => 'constraints',
    'SizedBox' => 'width', // SizedBox maps to width/height
    'Transform' => 'transform',
    'ClipRRect' || 'ClipOval' || 'ClipPath' => 'clipBehavior',
    'FractionallySizedBox' => 'widthFactor', // maps to widthFactor/heightFactor
    'Opacity' => 'opacity', // no direct Container param, but still valid
    'IntrinsicHeight' => 'intrinsicHeight',
    'IntrinsicWidth' => 'intrinsicWidth',
    'LimitedBox' => 'limitedBox',
    _ => null,
  };
}

/// The set of widget names that are "Container-compatible".
const _containerCompatibleWidgets = {
  'Padding',
  'Align',
  'Center',
  'ColoredBox',
  'DecoratedBox',
  'ConstrainedBox',
  'SizedBox',
  'Transform',
  'ClipRRect',
  'ClipOval',
  'ClipPath',
  'FractionallySizedBox',
  'Opacity',
  'IntrinsicHeight',
  'IntrinsicWidth',
  'LimitedBox',
};

/// The minimum number of consecutive Container-compatible widgets in a
/// nesting chain before the lint triggers.
const _minSequence = 3;

class _Visitor extends SimpleAstVisitor<void> {
  final PreferContainer rule;

  _Visitor(this.rule);

  static const _containerCompatibleCheckers = TypeChecker.any([
    TypeChecker.fromName('Padding', packageName: 'flutter'),
    TypeChecker.fromName('Align', packageName: 'flutter'),
    TypeChecker.fromName('Center', packageName: 'flutter'),
    TypeChecker.fromName('ColoredBox', packageName: 'flutter'),
    TypeChecker.fromName('DecoratedBox', packageName: 'flutter'),
    TypeChecker.fromName('ConstrainedBox', packageName: 'flutter'),
    TypeChecker.fromName('SizedBox', packageName: 'flutter'),
    TypeChecker.fromName('Transform', packageName: 'flutter'),
    TypeChecker.fromName('ClipRRect', packageName: 'flutter'),
    TypeChecker.fromName('ClipOval', packageName: 'flutter'),
    TypeChecker.fromName('ClipPath', packageName: 'flutter'),
    TypeChecker.fromName('FractionallySizedBox', packageName: 'flutter'),
    TypeChecker.fromName('Opacity', packageName: 'flutter'),
    TypeChecker.fromName('IntrinsicHeight', packageName: 'flutter'),
    TypeChecker.fromName('IntrinsicWidth', packageName: 'flutter'),
    TypeChecker.fromName('LimitedBox', packageName: 'flutter'),
  ]);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node, node.staticType, node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final type = node.staticType;
    if (type == null || !_containerCompatibleCheckers.isExactlyType(type)) {
      return;
    }
    _check(node, type, node.argumentList, node.methodName);
  }

  void _check(
    Expression node,
    DartType? staticType,
    ArgumentList argumentList,
    AstNode reportNode,
  ) {
    // Only check if this is a container-compatible widget
    if (staticType == null) return;
    if (!_containerCompatibleCheckers.isExactlyType(staticType)) return;

    // Don't start a chain if this node is already a child of a
    // container-compatible parent (the parent's chain already includes us).
    if (_isChildOfContainerCompatibleWidget(node)) return;

    // Walk the child chain to find the sequence length
    final sequence = _collectSequence(node);
    if (sequence.length < _minSequence) return;

    // Check for conflicting parameters (e.g., two Padding widgets would
    // both try to set `padding` on Container — only one is allowed).
    if (_hasConflictingParams(sequence)) return;

    rule.reportAtNode(reportNode, arguments: ['${sequence.length}']);
  }

  /// Checks whether [node] is the `child` argument of a container-compatible
  /// parent widget.
  static bool _isChildOfContainerCompatibleWidget(Expression node) {
    final parent = node.parent;
    if (parent is! NamedExpression) return false;
    if (parent.name.label.name != 'child') return false;

    final grandParent = parent.parent;
    if (grandParent is! ArgumentList) return false;

    final greatGrandParent = grandParent.parent;
    if (greatGrandParent is InstanceCreationExpression) {
      final type = greatGrandParent.staticType;
      return type != null && _containerCompatibleCheckers.isExactlyType(type);
    }
    if (greatGrandParent is MethodInvocation) {
      final type = greatGrandParent.staticType;
      return type != null && _containerCompatibleCheckers.isExactlyType(type);
    }
    return false;
  }

  /// Collects the sequence of container-compatible widgets by walking the
  /// child chain.
  static List<_WidgetInfo> _collectSequence(Expression node) {
    final sequence = <_WidgetInfo>[];
    Expression? current = node;

    while (current != null) {
      final info = _getWidgetInfo(current);
      if (info == null) break;
      sequence.add(info);
      current = _getChildExpression(info.argumentList);
    }

    return sequence;
  }

  /// Extracts widget info from an expression if it's a container-compatible
  /// widget.
  static _WidgetInfo? _getWidgetInfo(Expression expr) {
    if (expr is InstanceCreationExpression) {
      final type = expr.staticType;
      if (type == null || !_containerCompatibleCheckers.isExactlyType(type)) {
        return null;
      }
      final name = expr.constructorName.type.name.lexeme;
      if (!_containerCompatibleWidgets.contains(name)) return null;
      return _WidgetInfo(
        name: name,
        argumentList: expr.argumentList,
        node: expr,
      );
    }
    if (expr is MethodInvocation) {
      final type = expr.staticType;
      if (type == null || !_containerCompatibleCheckers.isExactlyType(type)) {
        return null;
      }
      final name = expr.methodName.name;
      if (!_containerCompatibleWidgets.contains(name)) return null;
      return _WidgetInfo(
        name: name,
        argumentList: expr.argumentList,
        node: expr,
      );
    }
    return null;
  }

  /// Gets the child expression from a widget's argument list.
  static Expression? _getChildExpression(ArgumentList argumentList) {
    final childArg = argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'child');
    return childArg?.expression;
  }

  /// Checks whether the sequence has conflicting parameters. Two widgets that
  /// map to the same Container parameter would conflict.
  static bool _hasConflictingParams(List<_WidgetInfo> sequence) {
    final usedParams = <String>{};
    for (final widget in sequence) {
      final param = _containerParamForWidget(widget.name);
      if (param == null) continue;
      // SizedBox maps to both width and height, so use a special key
      if (widget.name == 'SizedBox') {
        if (!usedParams.add('sizedBox')) return true;
      } else if (widget.name == 'FractionallySizedBox') {
        if (!usedParams.add('fractionallySizedBox')) return true;
      } else {
        if (!usedParams.add(param)) return true;
      }
    }
    return false;
  }
}

class _WidgetInfo {
  final String name;
  final ArgumentList argumentList;
  final Expression node;

  _WidgetInfo({
    required this.name,
    required this.argumentList,
    required this.node,
  });
}
