// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_shorthands_with_enums

// avoid_wildcard_cases_with_enums
//
// Warns when a switch over a non-nullable enum uses a wildcard or default
// case. A catch-all disables exhaustiveness checking, so a new enum
// constant silently inherits behaviour nobody chose for it.

enum Status { active, inactive, pending }

// ❌ Bad: wildcard in a switch expression
String badSwitchExpression(Status status) => switch (status) {
  Status.active => 'Active',
  // LINT: a new constant silently becomes 'Other'
  _ => 'Other',
};

// ❌ Bad: wildcard in a switch statement
void badSwitchStatement(Status status) {
  switch (status) {
    case Status.active:
      print('Active');
    // LINT: same problem
    case _:
      print('Other');
  }
}

// ❌ Bad: default has the same effect
void badDefault(Status status) {
  switch (status) {
    case Status.active:
      print('Active');
    // LINT: default disables the exhaustiveness check
    default:
      print('Other');
  }
}

// ✅ Good: every constant listed, compiler keeps the list honest
String goodExhaustive(Status status) => switch (status) {
  Status.active => 'Active',
  Status.inactive => 'Inactive',
  Status.pending => 'Pending',
};

// ✅ Good: group constants that share behaviour with ||
String goodGrouped(Status status) => switch (status) {
  Status.active => 'Active',
  Status.inactive || Status.pending => 'Not active',
};

// ✅ Edge case: a nullable enum genuinely needs a null case
String goodNullable(Status? status) => switch (status) {
  Status.active => 'Active',
  Status.inactive => 'Inactive',
  Status.pending => 'Pending',
  _ => 'None',
};

// ✅ Edge case: a guarded wildcard is conditional, so the compiler still
// checks the remaining constants
String goodGuarded(Status status, bool flag) => switch (status) {
  Status.active => 'Active',
  _ when flag => 'Flagged',
  Status.inactive => 'Inactive',
  Status.pending => 'Pending',
};

// ✅ Edge case: not an enum
String goodNonEnum(int value) => switch (value) {
  0 => 'zero',
  _ => 'other',
};
