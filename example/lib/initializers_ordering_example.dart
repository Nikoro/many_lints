// initializers_ordering
//
// Detects a constructor whose field initializers are not in the same order as
// the fields they assign. Unlike its siblings this has a useful default: the
// class's own field declaration order.

// ❌ Bad: the initializer list contradicts the field order above it
class BadPoint {
  final int x;
  final int y;

  // LINT: the initializer for 'x' is out of order
  BadPoint(int a, int b) : y = b, x = a;
}

// ✅ Good
class GoodPoint {
  final int x;
  final int y;

  GoodPoint(int a, int b) : x = a, y = b;
}

class Base {
  Base(int v);
}

// Edge case: super() and assert() have positions fixed by the language, so
// they are skipped rather than ordered.
class WithSuper extends Base {
  final int a;

  WithSuper(int x) : a = x, assert(x > 0), super(x);
}
