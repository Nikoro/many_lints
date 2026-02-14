// ignore_for_file: unused_local_variable

// avoid_collection_equality_checks
//
// Warns when mutable collections are compared with == or !=.
// Collections in Dart have reference equality, not structural equality,
// so == almost never produces the intended result.

// ❌ Bad: Comparing mutable collections with ==
void bad() {
  final list1 = [1, 2, 3];
  final list2 = [1, 2, 3];

  // LINT: Reference equality, not deep equality
  final same = list1 == list2; // always false!

  final set1 = {1, 2};
  final set2 = {1, 2};

  // LINT: Same problem with sets
  final sameSet = set1 == set2;

  final map1 = {'a': 1};
  final map2 = {'a': 1};

  // LINT: Same problem with maps
  final sameMap = map1 != map2;
}

// ✅ Good: Use deep equality or compare individual elements
void good() {
  // Const collections are fine — they are canonicalized
  final same = const [1, 2] == const [1, 2]; // true

  // Null checks are fine
  final List<int>? maybeList = null;
  final isNull = maybeList == null;

  // Non-collection equality is fine
  final a = 1;
  final b = 1;
  final sameInt = a == b;

  // Use DeepCollectionEquality from the `collection` package:
  // import 'package:collection/collection.dart';
  // final eq = DeepCollectionEquality().equals(list1, list2);
}
