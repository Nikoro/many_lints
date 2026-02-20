import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';
import '../flutter_widget_helpers.dart';

/// Fix that merges a sequence of nested widgets into a single Container.
class PreferContainerFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferContainer',
    DartFixKindPriority.standard,
    'Replace with Container',
  );

  PreferContainerFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  /// Maps widget names to the Container parameter names they contribute.
  static const _widgetParamMapping = <String, List<String>>{
    'Padding': ['padding'],
    'Align': ['alignment'],
    'Center': [], // Center contributes alignment: Alignment.center implicitly
    'ColoredBox': ['color'],
    'DecoratedBox': ['decoration'],
    'ConstrainedBox': ['constraints'],
    'SizedBox': ['width', 'height'],
    'Transform': ['transform'],
    'ClipRRect': ['clipBehavior'],
    'ClipOval': ['clipBehavior'],
    'ClipPath': ['clipBehavior'],
    'FractionallySizedBox': ['widthFactor', 'heightFactor', 'alignment'],
    'Opacity': ['opacity'],
    'IntrinsicHeight': [],
    'IntrinsicWidth': [],
    'LimitedBox': ['maxWidth', 'maxHeight'],
  };

  /// Widget names that are container-compatible.
  static const _containerCompatibleWidgets = {
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

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    // Find the outermost widget expression
    final Expression outerWidget;
    if (targetNode is ConstructorName) {
      final parent = targetNode.parent;
      if (parent is! InstanceCreationExpression) return;
      outerWidget = parent;
    } else if (targetNode is SimpleIdentifier &&
        targetNode.parent is MethodInvocation) {
      outerWidget = targetNode.parent! as MethodInvocation;
    } else {
      return;
    }

    // Collect the sequence of widgets
    final sequence = _collectSequence(outerWidget);
    if (sequence.length < 3) return;

    // Build the Container replacement
    final replacement = _buildContainerReplacement(sequence);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(outerWidget), replacement);
    });
  }

  /// Collects the sequence of container-compatible widgets in the chain.
  static List<WidgetInfo> _collectSequence(Expression node) {
    final sequence = <WidgetInfo>[];
    Expression? current = node;

    while (current != null) {
      final info = _getWidgetInfo(current);
      if (info == null) break;
      sequence.add(info);
      current = _getChildExpression(info.argumentList);
    }

    return sequence;
  }

  static WidgetInfo? _getWidgetInfo(Expression expr) {
    if (expr is InstanceCreationExpression) {
      final name = expr.constructorName.type.name.lexeme;
      if (!_containerCompatibleWidgets.contains(name)) return null;
      return (
        name: name,
        argumentList: expr.argumentList,
        node: expr as Expression,
      );
    }
    if (expr is MethodInvocation) {
      final name = expr.methodName.name;
      if (!_containerCompatibleWidgets.contains(name)) return null;
      return (
        name: name,
        argumentList: expr.argumentList,
        node: expr as Expression,
      );
    }
    return null;
  }

  static Expression? _getChildExpression(ArgumentList argumentList) {
    final childArg = argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'child');
    return childArg?.expression;
  }

  /// Builds the Container replacement string from the widget sequence.
  static String? _buildContainerReplacement(List<WidgetInfo> sequence) {
    final params = <String>[];
    String? keySource;
    String? childSource;

    for (final widget in sequence) {
      final mappedParams = _widgetParamMapping[widget.name];
      if (mappedParams == null) return null;

      for (final arg in widget.argumentList.arguments) {
        if (arg is! NamedExpression) continue;
        final argName = arg.name.label.name;

        if (argName == 'key' && keySource == null) {
          keySource = arg.expression.toSource();
          continue;
        }

        if (argName == 'child') continue;

        // Map the argument to Container's parameter
        final containerParam = _mapArgToContainerParam(widget.name, argName);
        if (containerParam != null) {
          params.add('$containerParam: ${arg.expression.toSource()}');
        }
      }

      // Center implicitly adds alignment: Alignment.center
      if (widget.name == 'Center') {
        // Only add if no explicit alignment argument was provided
        final hasAlignment = widget.argumentList.arguments
            .whereType<NamedExpression>()
            .any((e) => e.name.label.name == 'alignment');
        if (!hasAlignment) {
          params.add('alignment: Alignment.center');
        }
      }
    }

    // Get the child of the innermost widget
    final innermost = sequence.last;
    final innerChild = _getChildExpression(innermost.argumentList);
    if (innerChild != null) {
      childSource = innerChild.toSource();
    }

    final buffer = StringBuffer('Container(');
    if (keySource != null) {
      buffer.write('key: $keySource, ');
    }
    for (final param in params) {
      buffer.write('$param, ');
    }
    if (childSource != null) {
      buffer.write('child: $childSource, ');
    }
    buffer.write(')');

    return buffer.toString();
  }

  /// Maps a widget's argument name to the corresponding Container parameter.
  static String? _mapArgToContainerParam(String widgetName, String argName) {
    return switch ((widgetName, argName)) {
      ('Padding', 'padding') => 'padding',
      ('Align', 'alignment') => 'alignment',
      ('Align', 'widthFactor') =>
        'widthFactor', // Align-specific, not on Container
      ('Align', 'heightFactor') => 'heightFactor',
      ('Center', 'widthFactor') => null,
      ('Center', 'heightFactor') => null,
      ('Center', 'alignment') => 'alignment',
      ('ColoredBox', 'color') => 'color',
      ('DecoratedBox', 'decoration') => 'decoration',
      ('DecoratedBox', 'position') => 'foregroundDecoration',
      ('ConstrainedBox', 'constraints') => 'constraints',
      ('SizedBox', 'width') => 'width',
      ('SizedBox', 'height') => 'height',
      ('Transform', 'transform') => 'transform',
      ('Transform', 'alignment') => 'transformAlignment',
      ('Transform', 'origin') => null,
      ('ClipRRect', 'clipBehavior') => 'clipBehavior',
      ('ClipOval', 'clipBehavior') => 'clipBehavior',
      ('ClipPath', 'clipBehavior') => 'clipBehavior',
      ('FractionallySizedBox', 'widthFactor') => null,
      ('FractionallySizedBox', 'heightFactor') => null,
      ('FractionallySizedBox', 'alignment') => 'alignment',
      ('Opacity', 'opacity') => null,
      ('LimitedBox', 'maxWidth') => null,
      ('LimitedBox', 'maxHeight') => null,
      _ => null,
    };
  }
}
