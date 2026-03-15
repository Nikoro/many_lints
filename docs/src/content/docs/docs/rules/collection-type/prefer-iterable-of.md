---
title: prefer_iterable_of
description: "Use List.of() / Set.of() instead of .from() for type-safe copies."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_iterable_of
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

`List.from()` and `Set.from()` accept `Iterable<dynamic>` and perform a runtime cast, while `List.of()` and `Set.of()` are statically typed. When the source element type is already assignable to the target type, `.of()` provides compile-time type safety with no runtime overhead.

## Why use this rule

`.from()` silently casts elements at runtime, which can hide type errors until the code is executed. `.of()` catches type mismatches at compile time, making your code safer. Only use `.from()` when you intentionally need to downcast (e.g., `List<int>.from(numList)`).

**See also:** [List.of](https://api.dart.dev/stable/dart-core/List/List.of.html) | [Set.of](https://api.dart.dev/stable/dart-core/Set/Set.of.html)

## Don't

```dart
void example() {
  final intList = [1, 2, 3];

  // source is List<int>, target is List<int> — same type
  final copy = List<int>.from(intList);

  // source is List<int>, target is List<num> — int is subtype of num
  final numList = List<num>.from(intList);

  // without explicit type arg — inferred as List<int>
  final inferred = List.from(intList);

  final intSet = <int>{1, 2, 3};

  // source is Set<int>, target is Set<int> — same type
  final setCopy = Set<int>.from(intSet);
}
```

## Do

```dart
void example() {
  final intList = [1, 2, 3];

  final copy = List<int>.of(intList);
  final numList = List<num>.of(intList);
  final inferred = List.of(intList);

  final intSet = <int>{1, 2, 3};

  final setCopy = Set<int>.of(intSet);
  final setInferred = Set.of(intSet);

  // .from() is appropriate for downcasting
  final numSource = <num>[1, 2, 3];
  final intCast = List<int>.from(numSource); // runtime cast needed
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_iterable_of: false
```
