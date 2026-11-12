import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';
import '../flutter_widget_helpers.dart';

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

  static const _widgetParamMapping = <String, List<String>>{
    'Padding': ['padding'],
    'Align': ['alignment'],
    'Center': [],
    'ColoredBox': ['color'],
    'DecoratedBox': ['decoration'],
    'ConstrainedBox': ['constraints'],
    'SizedBox': ['width', 'height'],
    'Transform': ['transform'],
    'ClipRRect': ['clipBehavior'],
    'ClipOval': ['clipBehavior'],
    'ClipPath': ['clipBehavior'],
    'FractionallySizedBox': ['widthFactor', 'heightFactor', 'alignment'],
  };

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
  };

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final call = resolveWidgetCall(node);
    if (call == null) return;
    final outerWidget = call.node;

    final sequence = _collectSequence(outerWidget);
    if (sequence.length < 3) return;

    final replacement = _buildContainerReplacement(sequence);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(outerWidget), replacement);
    });
  }

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
        .whereType<NamedArgument>()
        .firstWhereOrNull((e) => e.name.lexeme == 'child');
    return childArg?.argumentExpression;
  }

  static String? _buildContainerReplacement(List<WidgetInfo> sequence) {
    final params = <String>[];
    String? keySource;
    String? childSource;

    for (final widget in sequence) {
      final mappedParams = _widgetParamMapping[widget.name];
      if (mappedParams == null) return null;

      for (final arg in widget.argumentList.arguments) {
        if (arg is! NamedArgument) continue;
        final argName = arg.name.lexeme;

        if (argName == 'key' && keySource == null) {
          keySource = arg.argumentExpression.toSource();
          continue;
        }

        if (argName == 'child') continue;

        final containerParam = _mapArgToContainerParam(widget.name, argName);
        if (containerParam != null) {
          params.add('$containerParam: ${arg.argumentExpression.toSource()}');
        }
      }

      if (widget.name == 'Center') {
        final hasAlignment = widget.argumentList.arguments
            .whereType<NamedArgument>()
            .any((e) => e.name.lexeme == 'alignment');
        if (!hasAlignment) {
          params.add('alignment: Alignment.center');
        }
      }
    }

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

  static String? _mapArgToContainerParam(String widgetName, String argName) {
    return switch ((widgetName, argName)) {
      ('Padding', 'padding') => 'padding',
      ('Align', 'alignment') => 'alignment',
      ('Align', 'widthFactor') => 'widthFactor',
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
      _ => null,
    };
  }
}
