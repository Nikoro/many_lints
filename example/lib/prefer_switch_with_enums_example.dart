// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_shorthands_with_enums

// prefer_switch_with_enums
//
// Warns when an if-else chain of three or more branches compares the same
// enum value against constants. A switch gets exhaustiveness checking.

enum Status { active, inactive, pending }

// ❌ Bad: an if-else chain over enum constants
String badChain(Status status) {
  // LINT: use a switch so the compiler checks every constant is handled
  if (status == Status.active) {
    return 'Active';
  } else if (status == Status.inactive) {
    return 'Inactive';
  } else if (status == Status.pending) {
    return 'Pending';
  }
  return '';
}

// ❌ Bad: operand order does not matter
String badReversed(Status status) {
  // LINT: same chain, written the other way round
  if (Status.active == status) {
    return 'Active';
  } else if (Status.inactive == status) {
    return 'Inactive';
  } else if (Status.pending == status) {
    return 'Pending';
  }
  return '';
}

// ✅ Good: a switch the compiler keeps honest
String goodSwitch(Status status) => switch (status) {
  Status.active => 'Active',
  Status.inactive => 'Inactive',
  Status.pending => 'Pending',
};

// ✅ Good: two branches are not worth restructuring
String goodShortChain(Status status) {
  if (status == Status.active) return 'Active';
  return 'Other';
}

// ✅ Edge case: branches testing different subjects cannot become a switch
String edgeCaseDifferentSubjects(Status a, Status b) {
  if (a == Status.active) {
    return 'A active';
  } else if (b == Status.inactive) {
    return 'B inactive';
  } else if (a == Status.pending) {
    return 'A pending';
  }
  return '';
}

// ✅ Edge case: a mixed condition breaks the chain
String edgeCaseMixed(Status status, bool flag) {
  if (status == Status.active) {
    return 'Active';
  } else if (flag) {
    return 'Flagged';
  } else if (status == Status.pending) {
    return 'Pending';
  }
  return '';
}

// ❌ Bad: comparisons combined with ||
bool badOrChain(Status status) {
  // LINT: three comparisons against the same subject
  if (status == Status.active ||
      status == Status.inactive ||
      status == Status.pending) {
    return true;
  }
  return false;
}

// ❌ Bad: membership test over a literal set of constants
bool badContains(Status status) {
  // LINT: adding a constant leaves this silently unchanged
  return {Status.active, Status.inactive, Status.pending}.contains(status);
}

// ✅ Good: a switch the compiler checks for exhaustiveness
bool goodOrPattern(Status status) => switch (status) {
  Status.active || Status.inactive || Status.pending => true,
};

// ✅ Good: fewer than three comparisons
bool goodShortOrChain(Status status) =>
    status == Status.active || status == Status.inactive;

// ✅ Good: a named set is a reusable collection, not an inlined branch
const _known = {Status.active, Status.inactive, Status.pending};
bool goodNamedSetContains(Status status) => _known.contains(status);
