// ignore_for_file: unused_local_variable

// avoid_cascade_after_if_null
//
// Warns when a cascade expression follows an if-null (??) operator
// without parentheses, which can produce unexpected results due to
// operator precedence.

class Kettle {
  void boil() {}
  int litres = 0;
}

// ❌ Bad: Cascade after if-null without parentheses
void bad(Kettle? spareKettle) {
  // LINT: Unclear whether ..boil() applies to the result of ?? or just Kettle()
  final kettle = spareKettle ?? Kettle()
    ..boil();

  // LINT: Multiple cascades after if-null
  final kettle2 = spareKettle ?? Kettle()
    ..boil()
    ..litres = 5;
}

// ✅ Good: Parentheses clarify intent
void good(Kettle? spareKettle) {
  // Cascade applies to the entire if-null expression
  final kettle = (spareKettle ?? Kettle())..boil();

  // Cascade applies only to the new instance
  final kettle2 = spareKettle ?? (Kettle()..boil());

  // No if-null involved, cascade is unambiguous
  final kettle3 = Kettle()..boil();
}
// ignore_for_file: many_lints/member_ordering
