import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that drops a `shrinkWrap: true` argument.
///
/// `shrinkWrap` defaults to `false`, so removing the argument restores the
/// lazy layout the rule asks for without changing anything else. When the
/// list genuinely needs to size itself to its children, the answer is a
/// different widget (`CustomScrollView` with slivers), which is a
/// restructuring the developer has to make.
class AvoidShrinkWrapInListsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidShrinkWrapInLists',
    DartFixKindPriority.standard,
    "Remove 'shrinkWrap'",
  );

  AvoidShrinkWrapInListsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final argument = node.thisOrAncestorOfType<NamedArgument>();
    if (argument == null) return;
    if (argument.name.lexeme != 'shrinkWrap') return;

    // Only the literal `true` is reported; leave anything else alone.
    if (argument.argumentExpression is! BooleanLiteral) return;

    final argumentList = argument.parent;
    if (argumentList is! ArgumentList) return;

    await builder.addDartFileEdit(file, (builder) {
      // The list owns the separating commas, so delete through
      // `nodeInList` to take the trailing comma with it.
      builder.addDeletion(range.nodeInList(argumentList.arguments, argument));
    });
  }
}
