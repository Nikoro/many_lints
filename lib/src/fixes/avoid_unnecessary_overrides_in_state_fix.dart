import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'avoid_unnecessary_overrides_fix.dart';

/// Fix that removes an unnecessary method override from a State class.
///
/// Deleting the override is exactly the edit [AvoidUnnecessaryOverridesFix]
/// performs, so only the [fixKind] — which is public surface tied to its own
/// rule — differs.
class AvoidUnnecessaryOverridesInStateFix extends AvoidUnnecessaryOverridesFix {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidUnnecessaryOverridesInState',
    DartFixKindPriority.standard,
    'Remove unnecessary override',
  );

  AvoidUnnecessaryOverridesInStateFix({required super.context});

  @override
  FixKind get fixKind => _fixKind;
}
