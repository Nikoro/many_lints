import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

import './type_checker.dart';

/// TypeChecker for the `@riverpod` / `@Riverpod(...)` annotation.
const riverpodAnnotationChecker = TypeChecker.fromName(
  'Riverpod',
  packageName: 'riverpod_annotation',
);

/// Whether [node] is annotated with `@riverpod` or `@Riverpod(...)`.
///
/// This is the cheap half of what a full Riverpod semantic layer offers:
/// enough to tell a generated provider declaration from an ordinary class or
/// function, without resolving the generated provider itself.
bool hasRiverpodAnnotation(AnnotatedNode node) {
  return node.metadata.any((annotation) {
    final element = annotation.element;
    // Both `@riverpod` (a const variable) and `@Riverpod()` (a constructor
    // call) resolve to an executable whose return type is `Riverpod`.
    if (element is! ExecutableElement) return false;
    return riverpodAnnotationChecker.isExactlyType(element.returnType);
  });
}

/// TypeChecker for the consumer *widgets* — those whose `build` receives a
/// Riverpod `ref` directly.
///
/// The hook variant is included because `hooks_riverpod` composes the two
/// ecosystems, and every rule reasoning about `ref` in a build method applies
/// to it identically.
const consumerWidgetChecker = TypeChecker.any([
  TypeChecker.fromName('ConsumerWidget', packageName: 'flutter_riverpod'),
  TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
]);

/// TypeChecker for the consumer *states* — the `State` halves that hold a
/// Riverpod `ref`.
const consumerStateChecker = TypeChecker.any([
  TypeChecker.fromName('ConsumerState', packageName: 'flutter_riverpod'),
  TypeChecker.fromName('HookConsumerState', packageName: 'hooks_riverpod'),
]);

/// TypeChecker for the `StatefulWidget` half of a consumer pair.
const consumerStatefulWidgetChecker = TypeChecker.fromName(
  'ConsumerStatefulWidget',
  packageName: 'flutter_riverpod',
);

/// TypeChecker for anything that owns a Riverpod `ref` — either half of the
/// widget/state split, hooks included.
const consumerChecker = TypeChecker.any([
  consumerWidgetChecker,
  consumerStateChecker,
]);

/// TypeChecker for Riverpod Notifier and AsyncNotifier base classes.
const notifierChecker = TypeChecker.any([
  TypeChecker.fromName('Notifier', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncNotifier', packageName: 'riverpod'),
]);

/// TypeChecker for the `AsyncValue` variants whose `value` may legitimately be
/// null.
///
/// `AsyncData` is excluded on purpose: its `hasValue` is always true, so a
/// null check there is the only thing separating the cases.
const asyncValueNullablePatternChecker = TypeChecker.any([
  TypeChecker.fromName('AsyncValue', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncLoading', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncError', packageName: 'riverpod'),
]);

/// TypeChecker for a Riverpod family — the callable that builds one provider
/// per argument.
const familyChecker = TypeChecker.fromName('Family', packageName: 'riverpod');

/// TypeChecker for a provider expression — either a provider itself or the
/// family that builds one.
const providerBaseChecker = TypeChecker.any([
  TypeChecker.fromName('ProviderBase', packageName: 'riverpod'),
  familyChecker,
]);

/// TypeChecker for the widgets that install a Riverpod scope.
///
/// `UncontrolledProviderScope` counts too: it takes an externally-owned
/// `ProviderContainer`, which is the standard shape for apps that build the
/// container themselves (tests, or state restored before `runApp`).
const providerScopeChecker = TypeChecker.any([
  TypeChecker.fromName('ProviderScope', packageName: 'flutter_riverpod'),
  TypeChecker.fromName(
    'UncontrolledProviderScope',
    packageName: 'flutter_riverpod',
  ),
]);
