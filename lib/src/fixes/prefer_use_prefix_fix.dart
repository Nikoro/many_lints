import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that adds the `use` prefix to a custom hook function name.
class PreferUsePrefixFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferUsePrefix',
    DartFixKindPriority.standard,
    "Add 'use' prefix",
  );

  PreferUsePrefixFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final offset = diagnosticOffset;
    final length = diagnosticLength;
    if (offset == null || length == null || length == 0) return;

    final name = unitResult.content.substring(offset, offset + length);
    final newName = _addUsePrefix(name);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(SourceRange(offset, length), newName);
    });
  }

  static String _addUsePrefix(String name) {
    if (name.startsWith('_')) {
      final rest = name.substring(1);
      if (rest.isEmpty) return '_use';
      return '_use${rest[0].toUpperCase()}${rest.substring(1)}';
    }
    if (name.isEmpty) return 'use';
    return 'use${name[0].toUpperCase()}${name.substring(1)}';
  }
}
