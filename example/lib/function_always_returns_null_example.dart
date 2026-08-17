// ignore_for_file: unused_element, unused_local_variable, avoid_print

// function_always_returns_null
//
// Warns when a function declared with a nullable return type returns null on
// every path. The nullable type promises a value that never arrives, forcing
// callers to null-check for nothing.

final Map<String, String> _cache = {};

// ❌ Bad: every path yields null
String? badLookup(String key) {
  // LINT: nothing can ever come back from this function
  if (key.isEmpty) return null;
  return null;
}

// ❌ Bad: the expression-body form is no different
// LINT: an arrow body returning null is still always null
String? badArrow(String key) => null;

// ❌ Bad: the same inside a class
class BadRepository {
  // LINT: the signature promises a String that never arrives
  String? find(String key) {
    return null;
  }
}

// ✅ Good: at least one path returns a value
String? goodLookup(String key) {
  if (key.isEmpty) return null;
  return _cache[key];
}

// ✅ Good: a function that produces nothing says so in its type
void record(String key) {
  print(key);
}

// ✅ Edge case: an override must keep the inherited signature
class Base {
  String? find(String key) => key;
}

class Child extends Base {
  @override
  String? find(String key) => null;
}

// ✅ Edge case: an async body's declared type wraps the value
Future<String?> asyncLookup(String key) async {
  return null;
}

// ✅ Edge case: a closure's return belongs to the closure
String? closureReturn(String key) {
  final inner = () => null;
  inner();
  return key;
}
// ignore_for_file: many_lints/function_always_returns_same_value
