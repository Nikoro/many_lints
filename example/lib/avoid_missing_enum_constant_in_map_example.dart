// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_shorthands_with_enums

// avoid_missing_enum_constant_in_map
//
// Warns when a map literal keyed by an enum omits some of its constants.
// A missing key makes the lookup return null rather than fail, so the gap
// surfaces far from the map itself.

enum Status { active, inactive, pending }

// ❌ Bad: `pending` is missing — lookups for it return null
// LINT: this map does not cover every Status constant
const _badLabels = <Status, String>{
  Status.active: 'Active',
  Status.inactive: 'Inactive',
};

// ❌ Bad: two constants missing
// LINT: only one of three constants is covered
const _badSparseLabels = <Status, String>{Status.active: 'Active'};

// ✅ Good: every constant covered
const _goodLabels = <Status, String>{
  Status.active: 'Active',
  Status.inactive: 'Inactive',
  Status.pending: 'Pending',
};

// ✅ Good: make the fallback explicit at the lookup instead
String describe(Status status) => _goodLabels[status] ?? 'Unknown';

// ✅ Edge case: an empty map is a deliberate starting point
final _goodEmpty = <Status, String>{};

// ✅ Edge case: a spread makes the final key set unknowable statically
final _goodSpread = <Status, String>{
  ..._goodLabels,
  Status.active: 'Overridden',
};

// ✅ Edge case: an `if` element has the same problem
Map<Status, String> buildConditional(bool includeInactive) {
  return <Status, String>{
    Status.active: 'Active',
    if (includeInactive) Status.inactive: 'Inactive',
  };
}

// ✅ Edge case: a computed key is not a constant reference
Map<Status, String> buildForCurrent(Status current) {
  return <Status, String>{current: 'Current'};
}

// ✅ Edge case: a set literal is not a map
final _goodSet = <Status>{Status.active};

// ✅ Edge case: non-enum keys are out of scope
const _goodStringKeys = <String, String>{'active': 'Active'};
