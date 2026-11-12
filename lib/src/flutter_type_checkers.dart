import './type_checker.dart';

const buildContextChecker = TypeChecker.fromName(
  'BuildContext',
  packageName: 'flutter',
);

const widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');

const statelessWidgetChecker = TypeChecker.fromName(
  'StatelessWidget',
  packageName: 'flutter',
);

const statefulWidgetChecker = TypeChecker.fromName(
  'StatefulWidget',
  packageName: 'flutter',
);

const containerChecker = TypeChecker.fromName(
  'Container',
  packageName: 'flutter',
);

const sizedBoxChecker = TypeChecker.fromName(
  'SizedBox',
  packageName: 'flutter',
);

const paddingChecker = TypeChecker.fromName('Padding', packageName: 'flutter');

const alignChecker = TypeChecker.fromName('Align', packageName: 'flutter');

const expandedChecker = TypeChecker.fromName(
  'Expanded',
  packageName: 'flutter',
);

const edgeInsetsChecker = TypeChecker.fromName(
  'EdgeInsets',
  packageName: 'flutter',
);

const rowChecker = TypeChecker.fromName('Row', packageName: 'flutter');

const columnChecker = TypeChecker.fromName('Column', packageName: 'flutter');

const flexChecker = TypeChecker.fromName('Flex', packageName: 'flutter');

const wrapChecker = TypeChecker.fromName('Wrap', packageName: 'flutter');

const anyFlexChecker = TypeChecker.any([
  rowChecker,
  columnChecker,
  flexChecker,
]);
