// ignore_for_file: unused_element

// avoid_empty_spread
//
// Warns when a spread element spreads an empty collection literal. It
// contributes nothing and is usually left behind after a refactor.

// ❌ Bad: spreading empty literals
List<int> badList() {
  // LINT: contributes nothing
  return [1, ...[], 2];
}

Set<int> badSet() {
  // LINT: same problem with a set
  return {1, ...{}, 2};
}

List<int> badTypedList() {
  // LINT: an explicit type argument does not change anything
  return [1, ...<int>[]];
}

// ✅ Good: no dead spread
List<int> goodList() => [1, 2];

// ✅ Good: spreading something with content
List<int> goodNonEmpty() => [
  1,
  ...[2, 3],
];

// ✅ Good: make the conditional intent explicit instead
List<int> goodConditional(bool includeExtras) {
  return [1, if (includeExtras) 2, 3];
}

// ✅ Edge case: a variable's emptiness is not knowable statically
List<int> goodVariableSpread(List<int> other) => [1, ...other];

// ✅ Edge case: null-aware spread of a variable
List<int> goodNullAwareSpread(List<int>? other) => [1, ...?other];
