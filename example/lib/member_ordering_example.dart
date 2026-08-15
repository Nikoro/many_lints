// ignore_for_file: unused_element, unused_field
// ignore_for_file: many_lints/prefer_primary_constructors
// ignore_for_file: many_lints/avoid_unnecessary_constructor
// ignore_for_file: many_lints/function_always_returns_null

// member_ordering
//
// Warns when a class member is declared before one the configured order puts
// earlier. The default puts the constructor first, then fields, then
// behaviour — the shape modern Dart and Flutter code already has.

// ❌ Bad: the order jumps around
class BadOrder {
  void submit() {}

  // LINT: a field below a method
  final int id = 0;

  // LINT: a constructor below a method
  BadOrder();
}

// ✅ Good: constructor, then state, then behaviour
class GoodOrder {
  GoodOrder(this.id);

  final int id;

  int get doubled => id * 2;

  void submit() {}

  void _log() {}
}

// ✅ Edge case: `==`, `hashCode` and `toString` are one block. Dart forces
// `hashCode` to be a getter, so ordering getters before methods would split
// a trio that belongs together — they are never reported.
class GoodValue {
  const GoodValue(this.id);

  final int id;

  @override
  bool operator ==(Object other) => other is GoodValue && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GoodValue($id)';
}

// ✅ Edge case: a Riverpod-style `build` is the state initialiser and comes
// first. Only a widget's `build` renders and belongs last, so helpers below
// this one are fine.
class GoodNotifier {
  Object? build() => null;

  void refresh() {}

  void _reset() {}
}
