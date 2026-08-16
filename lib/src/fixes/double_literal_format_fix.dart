import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:many_lints/src/double_literal_parts.dart';

/// Fix that rewrites a double literal with exactly one leading zero and no
/// redundant trailing zeros.
class DoubleLiteralFormatFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.doubleLiteralFormat',
    DartFixKindPriority.standard,
    'Reformat the double literal',
  );

  DoubleLiteralFormatFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final literal = node.thisOrAncestorOfType<DoubleLiteral>();
    if (literal == null) return;

    final parts = DoubleLiteralParts.tryParse(literal.literal.lexeme);
    if (parts == null) return;

    final normalized = parts.normalized();
    if (normalized == literal.literal.lexeme) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(literal), normalized);
    });
  }
}
