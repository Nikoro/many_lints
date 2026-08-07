// ignore_for_file: unused_element, unused_field

// avoid_nested_futures
//
// Warns about Future<Future<T>> annotations. Dart flattens futures, so the
// annotation never describes what the code actually produces.

Future<String> _fetchName() async => 'name';

// ❌ Bad: nested future return type
// LINT: this is really Future<String>
Future<Future<String>> badReturnType() => throw UnimplementedError();

// ❌ Bad: nested future field
class _BadHolder {
  // LINT: nested futures are flattened
  Future<Future<int>>? pending;
}

// ❌ Bad: nested future parameter
// LINT: a caller can never supply a genuinely nested future
void badParameter(Future<Future<int>> value) {}

// ✅ Good: a single future says what actually happens
Future<String> goodReturnType() async => _fetchName();

class _GoodHolder {
  Future<int>? pending;
}

void goodParameter(Future<int> value) {}

// ✅ Good: a future of a collection is a normal shape
Future<List<int>> goodFutureOfList() => throw UnimplementedError();

// ✅ Good: a list of futures is also normal
List<Future<int>> goodListOfFutures() => throw UnimplementedError();
