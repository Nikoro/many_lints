import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'insert_guard_before_statement_fix.dart';

/// Fix that adds `if (!mounted) return;` before ref.read() after an async gap.
class UseRefReadSynchronouslyFix extends InsertGuardBeforeStatementFix {
  static const _fixKind = FixKind(
    'many_lints.fix.useRefReadSynchronously',
    DartFixKindPriority.standard,
    "Add 'if (!mounted) return;' guard",
  );

  UseRefReadSynchronouslyFix({required super.context});

  @override
  FixKind get fixKind => _fixKind;

  @override
  String get guardSource => 'if (!mounted) return;';
}
