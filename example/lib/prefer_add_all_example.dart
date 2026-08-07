// ignore_for_file: unused_element

// prefer_add_all
//
// Warns when a for-in loop does nothing but add each element to another
// collection. That is addAll() spelled out across three lines.

// ❌ Bad: an add-only loop
void badCopy(List<int> target, List<int> source) {
  // LINT: use target.addAll(source)
  for (final item in source) {
    target.add(item);
  }
}

// ❌ Bad: same shape without braces
void badCopyNoBraces(List<int> target, List<int> source) {
  // LINT: use target.addAll(source)
  for (final item in source) target.add(item);
}

class _Holder {
  final List<int> items = [];

  // ❌ Bad: adding into a field
  void badCopyIntoField(List<int> source) {
    // LINT: use items.addAll(source)
    for (final item in source) {
      items.add(item);
    }
  }
}

// ✅ Good: one call, clear intent
void goodCopy(List<int> target, List<int> source) {
  target.addAll(source);
}

// ✅ Good: the loop transforms, so it is a map not a copy
void goodTransform(List<String> target, List<int> source) {
  for (final item in source) {
    target.add('$item');
  }
}

// ✅ Good: a condition means it is a filter
void goodFilter(List<int> target, List<int> source) {
  for (final item in source) {
    if (item.isEven) target.add(item);
  }
}

// ✅ Good: the body does more than add
void goodExtraWork(List<int> target, List<int> source) {
  for (final item in source) {
    target.add(item);
    print(item);
  }
}

// ✅ Edge case: an indexed loop may skip or reorder elements
void edgeCaseIndexed(List<int> target, List<int> source) {
  for (var i = 0; i < source.length; i += 2) {
    target.add(source[i]);
  }
}

// ❌ Bad: consecutive add() calls on the same collection
void badConsecutiveAdds(List<String> values) {
  values.add('first');
  // LINT: use values.addAll(['first', 'second'])
  values.add('second');
}

// ✅ Good: one addAll with a collection literal
void goodConsecutiveAdds(List<String> values) {
  values.addAll(['first', 'second']);
}

// ✅ Good: another statement breaks the run
void goodInterleaved(List<String> values) {
  values.add('first');
  print('between');
  values.add('second');
}

// ✅ Good: different receivers
void goodDifferentTargets(List<String> a, List<String> b) {
  a.add('x');
  b.add('y');
}
