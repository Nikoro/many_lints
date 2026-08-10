import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'insert_guard_before_statement_fix.dart';

/// Fix that adds `if (!ref.mounted) return;` before ref/state access after
/// an async gap.
class UseRefAndStateSynchronouslyFix extends InsertGuardBeforeStatementFix {
  static const _fixKind = FixKind(
    'many_lints.fix.useRefAndStateSynchronously',
    DartFixKindPriority.standard,
    "Add 'if (!ref.mounted) return;' guard",
  );

  UseRefAndStateSynchronouslyFix({required super.context});

  @override
  FixKind get fixKind => _fixKind;

  @override
  String get guardSource => 'if (!ref.mounted) return;';
}
