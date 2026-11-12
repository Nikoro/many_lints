import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';
import '../fpdart_type_checkers.dart';

typedef _Step = ({String name, String source});

class ConvertFlatMapToDoNotation extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertFlatMapToDoNotation',
    30,
    "Convert to 'Do' notation",
  );

  ConvertFlatMapToDoNotation({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final outermost = _outermostFlatMap();
    if (outermost == null) return;

    final target = outermost.realTarget;
    if (target == null) return;

    final wrapperType = outermost.staticType;
    if (wrapperType == null) return;

    final wrapper = _wrapperName(wrapperType);
    if (wrapper == null) return;

    final steps = <_Step>[];
    final firstName = _parameterNameOf(outermost);
    if (firstName == null) return;
    steps.add((name: firstName, source: target.toSource()));

    final returned = _collectSteps(outermost, steps);
    if (returned == null) return;
    if (steps.length < 2) return;

    // Edge case: the nest often starts mid-line, so indent from the line's leading whitespace
    final indent = _leadingWhitespaceOf(outermost.offset);
    final body = StringBuffer('$wrapper.Do((\$) {\n');
    for (final step in steps) {
      body.write('$indent  final ${step.name} = \$(${step.source});\n');
    }
    body.write('$indent  return $returned;\n');
    body.write('$indent})');

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(outermost), body.toString());

      // Edge case: offsets count from the replacement text, which starts at the node offset
      var cursor = outermost.offset + '$wrapper.Do((\$) {\n'.length;
      for (final step in steps) {
        final nameOffset = cursor + indent.length + 2 + 'final '.length;
        builder.addLinkedPosition(
          SourceRange(nameOffset, step.name.length),
          step.name,
        );
        cursor +=
            indent.length +
            2 +
            'final ${step.name} = \$(${step.source});\n'.length;
      }
    });
  }

  String _leadingWhitespaceOf(int offset) {
    final content = unitResult.content;
    if (offset <= 0) return '';

    final lineStart = content.lastIndexOf('\n', offset - 1) + 1;

    var end = lineStart;
    while (end < content.length &&
        (content[end] == ' ' || content[end] == '\t')) {
      end++;
    }

    return content.substring(lineStart, end);
  }

  MethodInvocation? _outermostFlatMap() {
    MethodInvocation? outermost;

    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is MethodInvocation && _isFpdartFlatMap(current)) {
        outermost = current;
      }
    }

    return outermost;
  }

  bool _isFpdartFlatMap(MethodInvocation node) {
    if (node.methodName.name != 'flatMap') return false;

    final targetType = node.realTarget?.staticType;
    return targetType != null &&
        anyFpdartChecker.isAssignableFromType(targetType);
  }

  String? _parameterNameOf(MethodInvocation node) {
    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return null;

    final callback = arguments.first.argumentExpression;
    if (callback is! FunctionExpression) return null;

    final parameters = callback.parameters?.parameters;
    if (parameters == null || parameters.length != 1) return null;

    return parameters.first.name?.lexeme;
  }

  Expression? _callbackBodyOf(MethodInvocation node) {
    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return null;

    final callback = arguments.first.argumentExpression;
    if (callback is! FunctionExpression) return null;

    return maybeGetSingleReturnExpression(callback.body);
  }

  String? _collectSteps(MethodInvocation node, List<_Step> steps) {
    final body = _callbackBodyOf(node);
    if (body == null) return null;

    final inner = body.unParenthesized;
    if (inner is MethodInvocation && _isFpdartFlatMap(inner)) {
      final name = _parameterNameOf(inner);
      final target = inner.realTarget;
      if (name == null || target == null) return null;

      steps.add((name: name, source: target.toSource()));
      return _collectSteps(inner, steps);
    }

    return _unwrapLift(inner);
  }

  String? _unwrapLift(Expression expression) {
    if (expression is InstanceCreationExpression) {
      final constructorName = expression.constructorName;
      final element = constructorName.element;
      if (element != null &&
          anyFpdartChecker.isExactly(element.enclosingElement)) {
        final name = constructorName.name?.name;
        if (name == 'of' || name == 'right') {
          final arguments = expression.argumentList.arguments;
          if (arguments.length == 1) {
            final argument = arguments.first;
            if (argument is Expression) return argument.toSource();
          }
        }
      }
    }

    return '\$(${expression.toSource()})';
  }

  String? _wrapperName(DartType type) =>
      type is InterfaceType && anyFpdartChecker.isAssignableFromType(type)
      ? type.element.name
      : null;
}
