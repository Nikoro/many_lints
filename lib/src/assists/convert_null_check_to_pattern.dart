import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../null_check_pattern_conversion.dart';

/// Converts `if (x != null)` into `if (x case final y?)`.
///
/// **Example**:
///
/// ```dart
/// if (userData != null) {
///   sendEvent(userData!.name);
/// }
/// ```
///
/// becomes
///
/// ```dart
/// if (userData case final userData_?) {
///   sendEvent(userData_!.name);
/// }
/// ```
///
/// ## Why this is worth doing
///
/// Dart promotes locals and parameters after `x != null`, but **not fields**:
/// another method could reassign a field between the check and the use, so the
/// analyzer refuses to promote it and every access inside the branch needs a
/// `!`. Binding the value to a pattern variable sidesteps that — the variable
/// is a fresh local the compiler can promote, so the `!` becomes unnecessary.
///
/// The conversion is semantics-preserving in both directions: the branch is
/// taken on exactly the same values as before, and an `else` still runs when
/// the value is null.
///
/// ## Why an assist rather than a quick fix
///
/// The new variable needs a name, and only the author knows the good one. The
/// name is emitted as a linked edit position so renaming it is part of applying
/// the assist rather than a follow-up chore.
///
/// It also rewrites the whole `if`, while `avoid_non_null_assertion` reports on
/// the `!` *inside* the branch. A fix that restructures the statement above the
/// reported node would be hard to predict, and "apply all" would rewrite every
/// guard in a file in one keystroke.
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

    // Built once so the linked-edit offset is derived from the exact text
    // written, rather than re-adding the same lengths a second time.
    final prefix = '${target.checkedSource} case final ';
    final replacement = '$prefix$name?';

    await builder.addDartFileEdit(file, (builder) {
      // Rewrite only the condition; the branches keep their own formatting.
      builder.addSimpleReplacement(
        SourceRange(target.condition.offset, target.condition.length),
        replacement,
      );

      // Every `checked!` inside the guarded branch becomes a plain read of the
      // bound variable, which is what makes the conversion worth applying.
      for (final bang in target.bangsInGuardedBranch) {
        builder.addSimpleReplacement(
          SourceRange(bang.offset, bang.length),
          name,
        );
      }

      // Bare reads of the same storage have to follow, or the branch would
      // mix the old nullable expression with the new variable.
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
