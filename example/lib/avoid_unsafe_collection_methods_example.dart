// ignore_for_file: unused_element, unused_local_variable

// avoid_unsafe_collection_methods
//
// Warns when first, last, single or reduce is used on a collection with no
// emptiness check in the enclosing function. All four throw a StateError on
// an empty iterable, from inside dart:core.

import 'package:collection/collection.dart';

// ❌ Bad: unguarded access that throws on an empty collection
int _badFirst(List<int> items) {
  // LINT: throws when items is empty
  return items.first;
}

int _badLast(List<int> items) {
  // LINT: same problem
  return items.last;
}

int _badSingle(Iterable<int> items) {
  // LINT: throws when items is empty (and when it has more than one element)
  return items.single;
}

int _badReduce(Iterable<int> items) {
  // LINT: reduce has no seed value, so an empty iterable throws
  return items.reduce((a, b) => a + b);
}

// ✅ Good: guarded by an emptiness check
int? _goodGuarded(List<int> items) {
  if (items.isEmpty) return null;
  return items.first;
}

// ✅ Good: guarded in the other direction
int? _goodPositiveGuard(List<int> items) {
  if (items.isNotEmpty) {
    return items.first;
  }
  return null;
}

// ✅ Good: null-returning variants never throw
int? _goodFirstOrNull(List<int> items) => items.firstOrNull;

// ✅ Good: fold supplies a seed, so an empty collection is fine
int _goodFold(Iterable<int> items) => items.fold(0, (a, b) => a + b);

// ✅ Edge case: a literal with elements is provably non-empty
int _goodLiteral() => [1, 2, 3].first;

// ✅ Edge case: a chained expression has no name to match a guard against,
// so it is never reported
int _edgeCaseChained(List<int> items) {
  return items.where((i) => i.isEven).first;
}

// ✅ Edge case: `first` on a type that is not an Iterable
class _Pair {
  const _Pair(this.first, this.last);

  final int first;
  final int last;
}

int _edgeCaseNonCollection(_Pair pair) => pair.first;
// ignore_for_file: many_lints/prefer_primary_constructors
