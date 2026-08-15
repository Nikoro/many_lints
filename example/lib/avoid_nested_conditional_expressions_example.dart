// ignore_for_file: unused_element

// avoid_nested_conditional_expressions
//
// Warns when a conditional expression is nested inside another one, packing a
// decision tree onto one line.

// ❌ Bad: the reader has to track which `?` each `:` belongs to
// LINT: nested two deep
String badLabel(int score) =>
    score > 100 ? 'high' : (score > 50 ? 'medium' : 'low');

// ✅ Good: a switch expression lines the branches up
String goodLabel(int score) => switch (score) {
  > 100 => 'high',
  > 50 => 'medium',
  _ => 'low',
};

// ✅ Good: a single conditional is fine
String goodSimple(int score) => score > 100 ? 'high' : 'low';
