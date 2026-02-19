import 'package:many_lints/src/type_checker.dart';

/// TypeChecker for Riverpod Notifier and AsyncNotifier base classes.
const notifierChecker = TypeChecker.any([
  TypeChecker.fromName('Notifier', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncNotifier', packageName: 'riverpod'),
]);
