// ignore_for_file: unused_element

// avoid_duplicate_collection_elements
//
// Warns when a list literal contains the same element twice. Sets and maps
// are covered by the analyzer's own duplicate diagnostics.

enum Status { active, inactive, pending }

const _limit = 10;

// ❌ Bad: repeated literal
// LINT: 1 already appears in this list
final _badNumbers = [1, 2, 1];

// ❌ Bad: repeated string
// LINT: 'a' already appears
final _badNames = ['a', 'b', 'a'];

// ❌ Bad: repeated enum constant
// LINT: Status.active already appears
final _badStatuses = [Status.active, Status.inactive, Status.active];

// ❌ Bad: repeated constant reference
// LINT: limit already appears
final _badConstants = [_limit, 20, _limit];

// ✅ Good: distinct elements
final _goodNumbers = [1, 2, 3];

final _goodStatuses = [Status.active, Status.inactive, Status.pending];

// ✅ Edge case: repeated calls may produce different values
int _next() => 0;

final _goodCalls = [_next(), _next()];

// ✅ Edge case: a spread makes the contents unknowable
final _base = [1, 2];
final _goodSpread = [1, ..._base, 1];

// ✅ Edge case: an if element has the same problem
List<int> goodConditional(bool flag) => [1, if (flag) 2, 1];
