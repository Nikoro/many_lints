// ignore_for_file: unused_local_variable, unused_element

// avoid_accessing_collections_by_constant_index
//
// Warns when a collection is accessed by a constant index inside a loop body.
// A constant index never changes with the loop, suggesting the access should
// either be moved outside the loop or use a loop-dependent index.

const _array = [1, 2, 3, 4, 5, 6, 7, 8, 9];

// ❌ Bad: Constant index access inside a loop

void badExamples() {
  // LINT: Integer literal index inside for-in loop
  for (final element in _array) {
    _array[0];
  }

  // LINT: Integer literal index inside for loop
  for (var i = 0; i < _array.length; i++) {
    _array[0];
  }

  // LINT: Const variable index inside loop
  const idx = 2;
  for (final element in _array) {
    _array[idx];
  }

  // LINT: Integer literal index inside while loop
  var j = 0;
  while (j < _array.length) {
    _array[0];
    j++;
  }

  // LINT: Integer literal index inside do-while loop
  var k = 0;
  do {
    _array[0];
    k++;
  } while (k < _array.length);
}

// ✅ Good: Correct usage patterns

void goodExamples() {
  // OK: Access outside of a loop
  final first = _array[0];

  // OK: Loop variable used as index
  for (var i = 0; i < _array.length; i++) {
    _array[i];
  }

  // OK: Mutable variable used as index
  var idx = 0;
  for (final element in _array) {
    _array[idx];
    idx++;
  }

  // OK: Expression-based index
  for (var i = 0; i < _array.length; i++) {
    _array[i + 1];
  }
}
