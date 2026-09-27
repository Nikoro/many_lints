// ignore_for_file: unused_field, unused_element

// prefer_primary_constructors
//
// Warns when a class or enum constructor could move into the type header as a
// primary constructor (Dart 3.13+). Types without a constructor are left alone.

// ❌ Bad: the fields, the parameters and the assignments are three copies of
// the same list.

// LINT: becomes `class BadPoint(final int x, final int y) { ... }`
class BadPoint {
  final int x;
  final int y;
  BadPoint(this.x, this.y);

  int get sum => x + y;
}

// LINT: `const` moves onto the header — `class const BadOffset(final int dx);`
class BadOffset {
  final int dx;
  const BadOffset(this.dx);
}

// LINT: the initializer list moves into `this : doubled = seed * 2;`
class BadSeeded {
  final int id;
  final int doubled;
  BadSeeded(this.id, int seed) : doubled = seed * 2;
}

// LINT: becomes `enum BadCurrency(final String symbol) { ... }`
enum BadCurrency {
  pln('zł'),
  eur('€');

  const BadCurrency(this.symbol);

  final String symbol;
}

// ✅ Good: primary constructors.
class GoodPoint(final int x, final int y) {
  int get sum => x + y;
}

class const GoodOffset(final int dx);

class GoodSeeded(final int id, int seed) {
  final int doubled;

  this : doubled = seed * 2;
}

enum GoodCurrency(final String symbol) {
  pln('zł'),
  eur('€'),
}

// ✅ Good: no constructor, so there is nothing to move. An empty `()` in the
// header would say nothing.
enum Sport { squash, padel }

abstract interface class Gateway {
  Future<void> send();
}

// ✅ Good: a second generative constructor that does not redirect cannot sit
// beside a primary constructor.
class Pair {
  final int x;
  Pair(this.x);
  Pair.zero() : x = 0;
}
// ignore_for_file: many_lints/member_ordering
// ignore_for_file: many_lints/prefer_declaring_const_constructor
