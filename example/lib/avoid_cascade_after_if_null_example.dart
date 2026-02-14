// ignore_for_file: unused_local_variable

// avoid_cascade_after_if_null
//
// Warns when a cascade expression follows an if-null (??) operator
// without parentheses, which can produce unexpected results due to
// operator precedence.

class Cow {
  void moo() {}
  int age = 0;
}

// ❌ Bad: Cascade after if-null without parentheses
void bad(Cow? nullableCow) {
  // LINT: Unclear whether ..moo() applies to the result of ?? or just Cow()
  final cow = nullableCow ?? Cow()
    ..moo();

  // LINT: Multiple cascades after if-null
  final cow2 = nullableCow ?? Cow()
    ..moo()
    ..age = 5;
}

// ✅ Good: Parentheses clarify intent
void good(Cow? nullableCow) {
  // Cascade applies to the entire if-null expression
  final cow = (nullableCow ?? Cow())..moo();

  // Cascade applies only to the new instance
  final cow2 = nullableCow ?? (Cow()..moo());

  // No if-null involved, cascade is unambiguous
  final cow3 = Cow()..moo();
}
