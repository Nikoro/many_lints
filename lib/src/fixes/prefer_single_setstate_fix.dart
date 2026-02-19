import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that merges multiple `setState` calls into a single invocation.
class PreferSingleSetstateFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferSingleSetstate',
    DartFixKindPriority.standard,
    'Merge setState calls into one',
  );

  PreferSingleSetstateFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodInvocation) return;

    // Find the enclosing method to collect all setState calls
    final method = _findEnclosingMethod(targetNode);
    if (method == null) return;

    final collector = _SetStateCollector();
    method.body.visitChildren(collector);

    final calls = collector.calls;
    if (calls.length < 2) return;

    // Build merged body from all setState callbacks
    final bodyParts = <String>[];
    for (final call in calls) {
      final args = call.argumentList.arguments;
      if (args.isEmpty) continue;
      final callback = args.first;
      if (callback is! FunctionExpression) continue;

      final body = callback.body;
      if (body is BlockFunctionBody) {
        for (final statement in body.block.statements) {
          bodyParts.add(statement.toSource());
        }
      } else if (body is ExpressionFunctionBody) {
        bodyParts.add('${body.expression.toSource()};');
      }
    }

    if (bodyParts.isEmpty) return;

    final mergedBody = bodyParts.join('\n      ');
    final mergedSetState = 'setState(() {\n      $mergedBody\n    })';

    await builder.addDartFileEdit(file, (builder) {
      // Replace the first setState call with the merged version
      builder.addSimpleReplacement(range.node(calls.first), mergedSetState);

      // Remove all subsequent setState calls (as ExpressionStatements)
      for (var i = 1; i < calls.length; i++) {
        final statement = calls[i].parent;
        if (statement is ExpressionStatement) {
          // Delete the full statement including any preceding whitespace/newline
          final content = unitResult.content;
          var start = statement.offset;
          while (start > 0 &&
              (content[start - 1] == ' ' || content[start - 1] == '\t')) {
            start--;
          }
          if (start > 0 && content[start - 1] == '\n') start--;

          builder.addDeletion(range.startOffsetEndOffset(start, statement.end));
        }
      }
    });
  }

  static MethodDeclaration? _findEnclosingMethod(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is MethodDeclaration) return current;
      current = current.parent;
    }
    return null;
  }
}

class _SetStateCollector extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState') {
      calls.add(node);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
