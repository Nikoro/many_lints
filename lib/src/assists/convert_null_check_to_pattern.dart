import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../null_check_pattern_conversion.dart';

class ConvertNullCheckToPattern extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertNullCheckToPattern',
    30,
    'Convert null check to pattern',
  );

  ConvertNullCheckToPattern({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final target = NullCheckGuard.tryRead(node);
    if (target == null) return;

    final name = target.suggestedName();

    final prefix = '${target.checkedSource} case final ';
    final replacement = '$prefix$name?';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(target.condition.offset, target.condition.length),
        replacement,
      );

      for (final bang in target.bangsInGuardedBranch) {
        builder.addSimpleReplacement(
          SourceRange(bang.offset, bang.length),
          name,
        );
      }

      for (final read in target.plainReadsInGuardedBranch) {
        builder.addSimpleReplacement(
          SourceRange(read.offset, read.length),
          name,
        );
      }

      builder.addLinkedPosition(
        SourceRange(target.condition.offset + prefix.length, name.length),
        name,
      );
    });
  }
}
