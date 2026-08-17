// pattern_fields_ordering
//
// Detects an object or record pattern whose named fields are not in the
// configured order.
//
//   pattern_fields_ordering:
//     order: alphabetical

class User {
  const User(this.age, this.name);

  final int age;
  final String name;
}

void badExample(Object o) {
  // LINT: the field 'age' is out of order
  if (o case User(name: final n, age: final a)) {
    print('$n$a');
  }
}

void goodExample(Object o) {
  if (o case User(age: final a, name: final n)) {
    print('$a$n');
  }
}

void edgeCases(Object o) {
  // A positional record pattern is identified by position, not by name.
  if (o case (final b, final a)) {
    print('$b$a');
  }
}
// ignore_for_file: many_lints/prefer_primary_constructors
