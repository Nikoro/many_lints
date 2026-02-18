import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `.indexOf() == -1` / `.indexOf() != -1` with `.contains()`.
class PreferContainsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferContains',
    DartFixKindPriority.standard,
    'Replace with .contains()',
  );

  PreferContainsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! BinaryExpression) return;

    final op = targetNode.operator.type;
    final left = targetNode.leftOperand;
    final right = targetNode.rightOperand;

    final MethodInvocation indexOfCall;
    if (left is MethodInvocation && left.methodName.name == 'indexOf') {
      indexOfCall = left;
    } else if (right is MethodInvocation &&
        right.methodName.name == 'indexOf') {
      indexOfCall = right;
    } else {
      return;
    }

    final target = indexOfCall.target;
    if (target == null) return;

    final args = indexOfCall.argumentList.arguments;
    if (args.isEmpty) return;

    final searchItem = args.first.toSource();
    final collection = target.toSource();

    // == -1 means "not found" → !collection.contains(item)
    // != -1 means "found" → collection.contains(item)
    final negate = op == TokenType.EQ_EQ;
    final replacement = negate
        ? '!$collection.contains($searchItem)'
        : '$collection.contains($searchItem)';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
