// ignore_for_file: unused_element, unused_field

// prefer_getter_over_method
//
// Warns when a no-argument method only reads a value, where a getter reads as
// the property it is.

// ❌ Bad: the empty parentheses suggest something happens when you call it
class BadOrder {
  final int amount = 0;

  // LINT: `order.total` reads as the property it is
  int total() => amount * 2;
}

// ✅ Good: a property, spelled as one
class GoodOrder {
  final int amount = 0;

  int get total => amount * 2;
}

// ✅ Edge case: a body that calls anything is not a plain read. `now()`
// answers differently on each call, and a getter promises a stable property.
class Clock {
  const Clock(this._now);

  final DateTime Function() _now;

  DateTime now() => _now();
}

// ✅ Edge case: `toJson` is what every serialiser looks for and `call` is the
// invocation operator in all but name — neither is a free choice.
class Payload {
  final int id = 0;

  Map<String, Object?> toJson() => {'id': id};
  int call() => id;
}

// ✅ Edge case: a Stream is subscribed to, not read as a property.
class Store {
  Store(this._values);

  final Stream<int> _values;

  Stream<int> watchValues() => _values;
}
// ignore_for_file: many_lints/prefer_declaring_const_constructor
