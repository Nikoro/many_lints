// ignore_for_file: unused_local_variable

// avoid_map_keys_contains
//
// Warns when using .keys.contains() instead of containsKey().
// .keys.contains is significantly slower than containsKey.

// ❌ Bad: Using .keys.contains()
void bad() {
  final map = {'lat': 52.2, 'lon': 21.0};

  // LINT: Use containsKey() instead
  final exists = map.keys.contains('lat');

  // LINT: Also in conditions
  if (map.keys.contains('foo')) {
    print('found');
  }
}

// ✅ Good: Using containsKey()
void good() {
  final map = {'lat': 52.2, 'lon': 21.0};

  final exists = map.containsKey('lat');

  if (map.containsKey('foo')) {
    print('found');
  }
}
