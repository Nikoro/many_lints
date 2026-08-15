// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_primary_constructors

// avoid_self_compare
//
// Warns when a value is passed to its own `compareTo`, so the result is
// always 0 and the comparison decides nothing.

class Person {
  const Person(this.surname, this.givenName);

  final String surname;
  final String givenName;
}

// ❌ Bad: the sort leaves the list in its original order
void badSort(List<Person> people) {
  // LINT: both sides read `a.surname`
  people.sort((a, b) => a.surname.compareTo(a.surname));
}

// ❌ Bad: a local compared against itself
int badLocal(String value) {
  // LINT: always 0
  return value.compareTo(value);
}

// ❌ Bad: the same field on both sides
class BadField {
  final String name = '';

  int compareName() {
    // LINT: always 0
    return name.compareTo(name);
  }
}

// ✅ Good: the two operands differ
void goodSort(List<Person> people) {
  people.sort((a, b) => a.surname.compareTo(b.surname));
}

// ✅ Good: comparing two different fields
class GoodField {
  final String first = '';
  final String second = '';

  int compareBoth() => first.compareTo(second);
}

// ✅ Edge case: each call may return a different value, so this is not
// necessarily 0 and the rule stays quiet.
int goodRepeatedCall(String Function() next) => next().compareTo(next());

// ✅ Edge case: a hand-written getter runs a body, so two reads need not
// agree.
class GoodMovingGetter {
  int _position = 0;

  String get current => '$_position';

  int compareCurrent() => current.compareTo(current);
}
