import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import 'package:many_lints/src/type_checker.dart';
import 'package:many_lints/src/ast_node_analysis.dart';

/// Converts an iterable call to `Iterable.map` with an optional
/// collect `Iterable.toList`/`Iterable.toSet` to a collection-for idiom.
///
/// **Example**:
///
/// ```dart
/// final iterable = [1, 2, 3];
/// final someList = iterable.map((e) => e * 2).toList();
/// final someSet = iterable.map((e) => e / 2).toSet();
/// ```
///
/// When assist is applied to `someList` and `someSet` the result is
///
/// ```dart
/// final iterable = [1, 2, 3];
/// final someList = [for(final e in iterable) e * 2];
/// final someSet = {for(final e in iterable) e / 2};
/// ```
class ConvertIterableMapToCollectionFor extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertIterableMapToCollectionFor',
    30,
    'Convert to collection-for',
  );

  ConvertIterableMapToCollectionFor({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Find the MethodInvocation at the current location
    final targetNode = node;
    MethodInvocation? methodInvocation;

    // Walk up the tree to find a MethodInvocation
    AstNode? current = targetNode;
    while (current != null) {
      if (current is MethodInvocation) {
        methodInvocation = current;
        break;
      }
      current = current.parent;
    }

    if (methodInvocation == null) return;

    await _handleIterable(methodInvocation, builder);
  }

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

  Future<void> _handleIterable(
    MethodInvocation node,
    ChangeBuilder builder,
  ) async {
    if (node case MethodInvocation(
      target: Expression(
        staticType: final targetType?,
        offset: final targetOffset,
        end: final targetEnd,
      ),
      methodName: SimpleIdentifier(name: 'map'),
      :final parent,
      argumentList: ArgumentList(
        arguments: [
          FunctionExpression(
            body: final functionBody,
            parameters: FormalParameterList(parameters: [final parameter]),
          ),
        ],
      ),
    ) when _iterableChecker.isAssignableFromType(targetType)) {
      final expression = maybeGetSingleReturnExpression(functionBody);
      if (expression == null) return;

      final parentCollectKind = _checkCollectKind(parent);
      final collectKind = parentCollectKind?.$1 ?? _IterableCollect.list;
      final nodeWithCollect = parentCollectKind?.$2 ?? node;

      await builder.addDartFileEdit(file, (builder) {
        builder
          ..addSimpleReplacement(
            SourceRange(
              nodeWithCollect.offset,
              targetOffset - nodeWithCollect.offset,
            ),
            '${collectKind.startDelimiter}for(final $parameter in ',
          )
          ..addSimpleReplacement(
            SourceRange(targetEnd, nodeWithCollect.end - targetEnd),
            ') $expression${collectKind.endDelimiter}',
          );
      });
    }
  }

  (_IterableCollect, MethodInvocation)? _checkCollectKind(AstNode? parent) {
    return switch (parent) {
      ParenthesizedExpression(:final parent) => _checkCollectKind(parent),
      MethodInvocation(methodName: SimpleIdentifier(name: 'toList')) => (
        _IterableCollect.list,
        parent,
      ),
      MethodInvocation(methodName: SimpleIdentifier(name: 'toSet')) => (
        _IterableCollect.set,
        parent,
      ),
      _ => null,
    };
  }
}

enum _IterableCollect {
  list,
  set;

  String get startDelimiter => switch (this) {
    list => '[',
    set => '{',
  };

  String get endDelimiter => switch (this) {
    list => ']',
    set => '}',
  };
}
