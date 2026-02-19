import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'prefer_shorthands_with_enums_fix.dart';

/// Fix that replaces explicit class prefix with dot shorthand for static fields.
///
/// Shares the same transformation logic as [PreferShorthandsWithEnumsFix].
class PreferShorthandsWithStaticFieldsFix extends PreferShorthandsWithEnumsFix {
  static const _fixKind = FixKind(
    'many_lints.fix.preferShorthandsWithStaticFields',
    DartFixKindPriority.standard,
    'Replace with dot shorthand',
  );

  PreferShorthandsWithStaticFieldsFix({required super.context});

  @override
  FixKind get fixKind => _fixKind;
}
