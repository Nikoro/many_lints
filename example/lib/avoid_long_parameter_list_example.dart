// ignore_for_file: unused_element

// avoid_long_parameter_list
//
// Warns when a function takes more parameters than the budget. Positional and
// named are counted separately, since named ones are labelled at the call site.

class DateRange {}

class Court {}

// ❌ Bad: five values travelling separately, in an order every caller must get
// right
// LINT: takes 5 positional parameters, over the limit of 4
void badSchedule(
  String title,
  DateTime start,
  DateTime end,
  String venue,
  int courtNumber,
) {}

// ✅ Good: the values that belong together have a name
void goodSchedule(String title, DateRange when, Court court) {}

// ✅ Edge case: named parameters are labelled and order-free, so they scale
// further — a widget constructor with several is not the problem.
void goodNamed({int? a, int? b, int? c, int? d, int? e, int? f, int? g}) {}
