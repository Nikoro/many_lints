// ignore_for_file: unused_local_variable

// avoid_collection_methods_with_unrelated_types
//
// Warns when collection methods are called with arguments whose types are
// unrelated to the collection's type parameter. Such calls always return
// null, false, or -1.

// ❌ Bad: Calling collection methods with unrelated types
void bad() {
  final list = <int>[1, 2, 3];

  // LINT: String argument on int list
  list.contains('a');

  // LINT: String argument on int list
  list.remove('a');

  final set = <int>{1, 2, 3};

  // LINT: String argument on int set
  set.contains('a');

  // LINT: String argument on int set
  set.lookup('a');

  final map = <int, String>{};

  // LINT: String key on int-keyed map
  map.containsKey('a');

  // LINT: int value on String-valued map
  map.containsValue(42);

  // LINT: String key on int-keyed map
  final value = map['a'];

  // LINT: String key on int-keyed map
  map.remove('a');
}

// ✅ Good: Using matching types
void good() {
  final list = <int>[1, 2, 3];
  list.contains(1);
  list.remove(2);
  list.indexOf(3);

  final set = <int>{1, 2, 3};
  set.contains(1);

  final map = <int, String>{};
  map.containsKey(1);
  map.containsValue('hello');
  final value = map[1];
  map.remove(1);

  // Subtypes are fine
  final numList = <num>[1, 2, 3];
  numList.contains(42); // int is subtype of num

  // Dynamic is allowed (type not statically known)
  dynamic unknown = 42;
  list.contains(unknown);
}
