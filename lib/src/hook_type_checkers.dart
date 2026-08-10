import './type_checker.dart';

/// TypeChecker for the widgets whose `build` may call hooks.
///
/// `HookConsumerWidget` is included because `hooks_riverpod` composes the two
/// ecosystems: it is a hook widget that also exposes a Riverpod `ref`.
const hookWidgetChecker = TypeChecker.any([
  TypeChecker.fromName('HookWidget', packageName: 'flutter_hooks'),
  TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
]);

/// TypeChecker for every scope in which a hook call is legal.
///
/// A superset of [hookWidgetChecker] that also admits `HookState`, whose
/// lifecycle methods are a valid place to call hooks. Rules asking "may a hook
/// appear here?" want this; rules asking "is this a hook *widget*?" want
/// [hookWidgetChecker], and conflating them would let a rule accept or reject
/// `HookState` by accident.
const hookScopeChecker = TypeChecker.any([
  hookWidgetChecker,
  TypeChecker.fromName('HookState', packageName: 'flutter_hooks'),
]);
