// ignore_for_file: unused_element
// ignore_for_file: many_lints/function_always_returns_null

// avoid_duplicate_mixins
//
// Warns when a `with` clause lists the same mixin more than once, where every
// application after the first contributes nothing.

mixin Loggable {
  void log(String message) {}
}

mixin Cacheable {
  void cache() {}
}

mixin Identified<T> {
  T? get id => null;
}

// ❌ Bad: the second `Loggable` adds nothing
// LINT: reported on the repeated mixin
class BadReport with Loggable, Loggable {}

// ❌ Bad: the duplicate sits among other mixins
// LINT: reported on the repeated mixin
class BadInvoice with Loggable, Cacheable, Loggable {}

// ❌ Bad: the same instantiation twice
// LINT: reported on the repeated mixin
class BadTicket with Identified<int>, Identified<int> {}

// ✅ Good: each mixin appears once
class GoodReport with Loggable, Cacheable {}

// ✅ Good: a single mixin
class GoodInvoice with Loggable {}

// ✅ Edge case: re-applying a mixin the superclass already has changes the
// linearization order, so it is a deliberate choice rather than a duplicate.
class Base with Loggable {}

class Derived extends Base with Loggable {}
