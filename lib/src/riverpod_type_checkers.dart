import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

import './type_checker.dart';

const riverpodAnnotationChecker = TypeChecker.fromName(
  'Riverpod',
  packageName: 'riverpod_annotation',
);

bool hasRiverpodAnnotation(AnnotatedNode node) {
  return node.metadata.any((annotation) {
    final element = annotation.element;
    // Edge case: `@riverpod` and `@Riverpod()` both resolve to an executable returning Riverpod
    if (element is! ExecutableElement) return false;
    return riverpodAnnotationChecker.isExactlyType(element.returnType);
  });
}

const riverpodRefChecker = TypeChecker.any([
  TypeChecker.fromName('WidgetRef', packageName: 'flutter_riverpod'),
  TypeChecker.fromName('WidgetRef', packageName: 'hooks_riverpod'),
  TypeChecker.fromName('Ref', packageName: 'flutter_riverpod'),
  TypeChecker.fromName('Ref', packageName: 'riverpod'),
]);

const consumerWidgetChecker = TypeChecker.any([
  TypeChecker.fromName('ConsumerWidget', packageName: 'flutter_riverpod'),
  TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
]);

const consumerStateChecker = TypeChecker.any([
  TypeChecker.fromName('ConsumerState', packageName: 'flutter_riverpod'),
  TypeChecker.fromName('HookConsumerState', packageName: 'hooks_riverpod'),
]);

const consumerStatefulWidgetChecker = TypeChecker.fromName(
  'ConsumerStatefulWidget',
  packageName: 'flutter_riverpod',
);

const consumerChecker = TypeChecker.any([
  consumerWidgetChecker,
  consumerStateChecker,
]);

const notifierChecker = TypeChecker.any([
  TypeChecker.fromName('Notifier', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncNotifier', packageName: 'riverpod'),
]);

const asyncValueNullablePatternChecker = TypeChecker.any([
  TypeChecker.fromName('AsyncValue', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncLoading', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncError', packageName: 'riverpod'),
]);

const familyChecker = TypeChecker.fromName('Family', packageName: 'riverpod');

const providerBaseChecker = TypeChecker.any([
  TypeChecker.fromName('ProviderBase', packageName: 'riverpod'),
  familyChecker,
]);

const providerScopeChecker = TypeChecker.any([
  TypeChecker.fromName('ProviderScope', packageName: 'flutter_riverpod'),
  TypeChecker.fromName(
    'UncontrolledProviderScope',
    packageName: 'flutter_riverpod',
  ),
]);
