// ignore_for_file: unused_element

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
