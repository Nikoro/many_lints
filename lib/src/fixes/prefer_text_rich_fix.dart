import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

/// Fix that replaces RichText with Text.rich.
class PreferTextRichFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferTextRich',
    DartFixKindPriority.standard,
    'Replace with Text.rich',
  );

  PreferTextRichFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    final ArgumentList argumentList;
    final AstNode replacementNode;

    if (targetNode is ConstructorName) {
      // InstanceCreationExpression case (const RichText(...) or RichText<T>(...))
      final parent = targetNode.parent;
      if (parent is! InstanceCreationExpression) return;
      argumentList = parent.argumentList;
      replacementNode = parent;
    } else if (targetNode is SimpleIdentifier) {
      // MethodInvocation case (RichText(...) without const/new/type args)
      final parent = targetNode.parent;
      if (parent is! MethodInvocation) return;
      argumentList = parent.argumentList;
      replacementNode = parent;
    } else {
      return;
    }

    final arguments = argumentList.arguments;

    // Find the `text` argument (the TextSpan)
    final textArgument = arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'text');

    if (textArgument == null) return;

    // Build the replacement: Text.rich(textSpan, otherArgs...)
    final textSpanSource = textArgument.expression.toSource();

    // Collect other arguments (excluding `text`)
    final otherArgs = <String>[];
    for (final arg in arguments) {
      if (arg == textArgument) continue;
      otherArgs.add(arg.toSource());
    }

    final buffer = StringBuffer('Text.rich(');
    buffer.write(textSpanSource);
    for (final other in otherArgs) {
      buffer.write(', ');
      buffer.write(other);
    }
    buffer.write(')');

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(replacementNode),
        buffer.toString(),
      );
    });
  }
}
