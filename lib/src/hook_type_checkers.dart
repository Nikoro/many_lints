import './type_checker.dart';

const hookWidgetChecker = TypeChecker.any([
  TypeChecker.fromName('HookWidget', packageName: 'flutter_hooks'),
  TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
]);

const hookScopeChecker = TypeChecker.any([
  hookWidgetChecker,
  TypeChecker.fromName('HookState', packageName: 'flutter_hooks'),
]);
