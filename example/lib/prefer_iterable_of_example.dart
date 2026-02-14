// ignore_for_file: unused_local_variable

// prefer_iterable_of
//
// Prefer List.of() / Set.of() over List.from() / Set.from() when the
// source element type is already assignable to the target element type.

// ❌ Bad: Using .from() when .of() is type-safe
class BadExamples {
  void listExamples() {
    final intList = [1, 2, 3];

    // LINT: source is List<int>, target is List<int> — same type
    final copy = List<int>.from(intList);

    // LINT: source is List<int>, target is List<num> — int is subtype of num
    final numList = List<num>.from(intList);

    // LINT: without explicit type arg — inferred as List<int>
    final inferred = List.from(intList);
  }

  void setExamples() {
    final intSet = <int>{1, 2, 3};

    // LINT: source is Set<int>, target is Set<int> — same type
    final copy = Set<int>.from(intSet);

    // LINT: without explicit type arg — inferred as Set<int>
    final inferred = Set.from(intSet);
  }
}

// ✅ Good: Using .of() for type-safe copies
class GoodExamples {
  void listExamples() {
    final intList = [1, 2, 3];

    final copy = List<int>.of(intList);
    final numList = List<num>.of(intList);
    final inferred = List.of(intList);
  }

  void setExamples() {
    final intSet = <int>{1, 2, 3};

    final copy = Set<int>.of(intSet);
    final inferred = Set.of(intSet);
  }
}

// ✅ Good: .from() is appropriate for downcasting
class DowncastExamples {
  void listDowncast() {
    final numList = <num>[1, 2, 3];

    // OK: narrowing from num to int — .from() is needed for runtime cast
    final intList = List<int>.from(numList);
  }

  void setDowncast() {
    final numSet = <num>{1, 2, 3};

    // OK: narrowing from num to int — .from() is needed for runtime cast
    final intSet = Set<int>.from(numSet);
  }
}
