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
