import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'prefer_returning_shorthands_fix.dart';

/// Fix that replaces explicit class constructor invocation with dot shorthand.
///
/// Shares the same transformation logic as [PreferReturningShorthandsFix],
/// but uses an empty string for unnamed constructors (producing `.` instead
/// of `.new`).
class PreferShorthandsWithConstructorsFix extends PreferReturningShorthandsFix {
  static const _fixKind = FixKind(
    'many_lints.fix.preferShorthandsWithConstructors',
    DartFixKindPriority.standard,
    'Replace with dot shorthand',
  );

  PreferShorthandsWithConstructorsFix({required super.context});

  @override
  FixKind get fixKind => _fixKind;

  @override
  String get unnamedConstructorReplacement => '';
}
