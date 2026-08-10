import './type_checker.dart';

/// TypeChecker for `BuildContext`, the handle onto a widget's position in the
/// tree.
const buildContextChecker = TypeChecker.fromName(
  'BuildContext',
  packageName: 'flutter',
);

/// TypeChecker for `Widget`, the base of everything in the tree.
const widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');

/// TypeChecker for `StatelessWidget`.
const statelessWidgetChecker = TypeChecker.fromName(
  'StatelessWidget',
  packageName: 'flutter',
);

/// TypeChecker for `StatefulWidget`.
const statefulWidgetChecker = TypeChecker.fromName(
  'StatefulWidget',
  packageName: 'flutter',
);

/// TypeChecker for `Container`, the composite widget several rules suggest
/// replacing with the single-purpose widget it stands in for.
const containerChecker = TypeChecker.fromName(
  'Container',
  packageName: 'flutter',
);

/// TypeChecker for `SizedBox`.
const sizedBoxChecker = TypeChecker.fromName(
  'SizedBox',
  packageName: 'flutter',
);

/// TypeChecker for `Padding`.
const paddingChecker = TypeChecker.fromName('Padding', packageName: 'flutter');

/// TypeChecker for `Align`.
const alignChecker = TypeChecker.fromName('Align', packageName: 'flutter');

/// TypeChecker for `Expanded`.
const expandedChecker = TypeChecker.fromName(
  'Expanded',
  packageName: 'flutter',
);

/// TypeChecker for `EdgeInsets`.
const edgeInsetsChecker = TypeChecker.fromName(
  'EdgeInsets',
  packageName: 'flutter',
);

/// TypeChecker for `Row`.
const rowChecker = TypeChecker.fromName('Row', packageName: 'flutter');

/// TypeChecker for `Column`.
const columnChecker = TypeChecker.fromName('Column', packageName: 'flutter');

/// TypeChecker for `Flex`, the shared base of `Row` and `Column`.
const flexChecker = TypeChecker.fromName('Flex', packageName: 'flutter');

/// TypeChecker for `Wrap`.
const wrapChecker = TypeChecker.fromName('Wrap', packageName: 'flutter');

/// TypeChecker for any flex container — `Row`, `Column`, or a direct `Flex`.
///
/// Carries no axis, for rules that only need to know a node *is* a flex.
/// Rules that also need the direction pair the checkers with a [FlexAxis]
/// themselves; see `flutter_widget_helpers.dart`.
const anyFlexChecker = TypeChecker.any([
  rowChecker,
  columnChecker,
  flexChecker,
]);
