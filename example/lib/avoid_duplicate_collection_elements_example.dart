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

// ❌ Bad: a spread no longer hides duplicates around it
final _base = [1, 2];
// LINT: 1 already appears in this list
final badAroundSpread = [1, ..._base, 1];

// ❌ Bad: an if element does not hide them either
// LINT: 1 already appears in this list
List<int> badAroundConditional(bool flag) => [1, if (flag) 2, 1];

// ❌ Bad: the same spread twice
// LINT: the second spread repeats every value
final badDuplicateSpread = [..._base, ..._base];

// ❌ Bad: the same if element twice
List<String> badDuplicateIfElement(List<int> items) => [
  if (items.isNotEmpty) 'value',
  // LINT: identical to the entry above
  if (items.isNotEmpty) 'value',
];

// ✅ Good: different spreads
final _extra = [3];
final goodSpreads = [..._base, ..._extra];

// ✅ Good: complementary conditions
List<String> goodIfElements(List<int> items) => [
  if (items.isNotEmpty) 'full',
  if (items.isEmpty) 'empty',
];

// ✅ Edge case: two calls may return different values, so they are not compared
List<int> _fetch() => [1];
final edgeCaseCallSpreads = [..._fetch(), ..._fetch()];
