// map_keys_ordering
//
// Detects a map literal whose keys are not in the configured order.
// Reports nothing until an `order:` is chosen:
//
//   map_keys_ordering:
//     order: alphabetical

// ❌ Bad: a lookup table that has to be read end to end
// LINT: the key 'apple' is out of order
const badLabels = {
  'banana': 'Banana',
  'apple': 'Apple',
  'cherry': 'Cherry',
  'date': 'Date',
  'elder': 'Elderberry',
};

// ✅ Good
const goodLabels = {
  'apple': 'Apple',
  'banana': 'Banana',
  'cherry': 'Cherry',
  'date': 'Date',
  'elder': 'Elderberry',
};

// Edge cases where the lint intentionally does NOT trigger

// Below `min_entries`, order carries no cost.
const short = {'banana': 1, 'apple': 2};

// A spread makes the literal's contents unsortable: ordering the rest around
// it would produce an arrangement the user cannot reach.
const base = {'fig': 1};
const spread = {'banana': 1, ...base, 'apple': 2, 'cherry': 3, 'date': 4};
