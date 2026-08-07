// async_value_nullable_pattern
//
// Warns when AsyncValue(:final value?) is matched on a nullable value type.
// The `?` pattern matches only non-null values, which is not the same question
// as "has this loaded?" — a successfully loaded null falls through to the
// loading branch, and the UI spins forever on data that already arrived.

import 'package:riverpod/riverpod.dart';

// ❌ Bad: A loaded `null` never matches, so it looks like "still loading"
void badNullable(AsyncValue<int?> asyncValue) {
  switch (asyncValue) {
    // LINT: Use `hasValue: true` to ask whether the value loaded
    case AsyncValue(:final value?):
      print(value);
    default:
      print('loading');
  }
}

// ✅ Good: `hasValue` asks the intended question
void goodNullable(AsyncValue<int?> asyncValue) {
  switch (asyncValue) {
    case AsyncValue(:final value, hasValue: true):
      print(value);
    default:
      print('loading');
  }
}

// ✅ Good: For a non-nullable value, null can only mean "not loaded"
void goodNonNullable(AsyncValue<int> asyncValue) {
  switch (asyncValue) {
    case AsyncValue(:final value?):
      print(value);
    default:
      print('loading');
  }
}

// ✅ Good: AsyncData.hasValue is always true, so the null check carries meaning
void goodAsyncData(AsyncValue<int?> asyncValue) {
  switch (asyncValue) {
    case AsyncData(:final value?):
      print(value);
    default:
      print('loading');
  }
}
