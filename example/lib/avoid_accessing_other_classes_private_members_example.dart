// ignore_for_file: unused_element, unused_local_variable
// ignore_for_file: many_lints/prefer_single_declaration_per_file
// ignore_for_file: many_lints/prefer_boolean_prefixes

// avoid_accessing_other_classes_private_members
//
// Detects one class reading another class's private member.
//
// Dart scopes privacy to the LIBRARY, not the class, so `_field` is visible to
// every declaration in the same file — and to every `part` of it. Most people
// write `_` meaning "mine", and the language quietly means "this file's". This
// rule makes the language behave the way the underscore already reads.

class Account {
  int _balance = 0;

  int get balance => _balance;

  // ✅ Good: another instance of the SAME class is the `==` / `copyWith`
  // pattern, not a violation.
  bool sameAs(Account other) => _balance == other._balance;
}

// ❌ Bad
class BadReport {
  // LINT: reaches into another class's private state. This compiles, because
  // both classes live in one library — which is exactly the gap.
  int total(Account account) => account._balance;
}

// ✅ Good: read the API the other class chose to expose.
class GoodReport {
  int total(Account account) => account.balance;
}
