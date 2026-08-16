// ignore_for_file: unused_field

// prefer_declaring_const_constructor
//
// Detects a class that could declare a const constructor but does not.
// `prefer_const_constructors` only fires where one already exists; this rule
// asks for the constructor in the first place.

// ❌ Bad: every field is final and the body is empty, but call sites cannot
// build this at compile time
class BadPoint {
  // LINT: 'BadPoint' could declare a const constructor
  BadPoint(this.x, this.y);

  final int x;
  final int y;
}

// ✅ Good
class GoodPoint {
  const GoodPoint(this.x, this.y);

  final int x;
  final int y;
}

// Edge cases where the lint intentionally does NOT trigger

// A mutable field rules const out.
class Mutable {
  Mutable(this.x);

  int x;
}

// An initializer whose value is a CALL is not const-evaluable, so suggesting
// const here would produce code that does not build. Both of this rule's
// first hits on a production codebase were exactly this shape.
class WithFallback {
  WithFallback([Object? source]) : _source = source ?? Object();

  final Object _source;
}

// A constructor with a body cannot be const.
class WithBody {
  WithBody(this.x) {
    print(x);
  }

  final int x;
}
