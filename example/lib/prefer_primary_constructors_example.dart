// ignore_for_file: unused_field, unused_element

// prefer_primary_constructors
//
// Warns when a class of final fields plus a field-assigning constructor could
// use a primary constructor (Dart 3.13+).

// ❌ Bad: the fields, the parameters and the assignments are three copies of
// the same list.

// LINT: collapses to `class BadPoint(final int x, final int y);`
class BadPoint {
  final int x;
  final int y;
  BadPoint(this.x, this.y);
}

// LINT: `const` moves onto the header — `class const BadOffset(final int dx);`
class BadOffset {
  final int dx;
  const BadOffset(this.dx);
}

// LINT: named parameters keep their braces —
// `class BadConfig({required final int retries});`
class BadConfig {
  final int retries;
  BadConfig({required this.retries});
}

// ✅ Good: primary constructors.
class GoodPoint(final int x, final int y);

class const GoodOffset(final int dx);

class GoodConfig({required final int retries});

// ✅ Good: has a getter, so the body has to survive — a primary constructor
// would still leave a `{ ... }` behind, which is a larger and more debatable
// edit than this rule makes.
class WithGetter {
  final int v;
  WithGetter(this.v);
  int get doubled => v * 2;
}

// ✅ Good: the initializer list does work beyond assigning fields.
class Guarded {
  final int x;
  final int doubled;
  Guarded(this.x) : doubled = x * 2;
}

// ✅ Good: a mutable field cannot become a declaring parameter without
// changing meaning.
class Counter {
  int count;
  Counter(this.count);
}

// ✅ Good: the parameter is renamed, so this is not a pure relocation of the
// field list.
class Indirect {
  final int x;
  Indirect(int value) : x = value;
}

// ✅ Good: a second constructor would have to redirect to the primary one.
class Pair {
  final int x;
  Pair(this.x);
  Pair.zero() : x = 0;
}

// ✅ Good: a superclass means construction has to forward to it.
class Base {
  const Base();
}

class Derived extends Base {
  final int x;
  Derived(this.x);
}
// ignore_for_file: many_lints/member_ordering
// ignore_for_file: many_lints/prefer_declaring_const_constructor
