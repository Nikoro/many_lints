---
title: avoid_misused_test_matchers
description: "Detect test matchers used with incompatible value types."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_misused_test_matchers
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Testing Rules</span>

Flags `expect()` calls where the matcher is incompatible with the actual value's type. For example, using `isNull` on a non-nullable type, `isEmpty` on an `int`, or `isList` on a `String`. Misused matchers can cause tests to always pass (hiding bugs) or always fail (making assertions useless).

## Why use this rule

A mismatched matcher silently undermines your test suite. `expect(42, isNull)` will always fail because `int` is non-nullable, while `expect(42, isNotNull)` will always pass, giving a false sense of coverage. This rule catches these type mismatches at analysis time before they reach CI.

**See also:** [test package - Matchers](https://pub.dev/packages/test#matchers)

## Don't

```dart
expect(someString, isList);       // String is not a List
expect(someNumber, isEmpty);      // int has no isEmpty
expect(someNumber, isNull);       // int is non-nullable
expect(someNumber, isNotNull);    // always true, redundant
expect(someNumber, hasLength(1)); // int has no length
expect(someString, isZero);       // String is not a num
expect(someNumber, isTrue);       // int is not a bool
expect(someString, isMap);        // String is not a Map
expect(true, isNegative);         // bool is not a num
```

## Do

```dart
expect(someList, isList);
expect(<String, int>{}, isMap);
expect(nullableValue, isNull);
expect(nullableValue, isNotNull);
expect(someList, isEmpty);
expect(someString, isEmpty);
expect(someList, hasLength(3));
expect(someNumber, isZero);
expect(5, isPositive);
expect(true, isTrue);
expect(false, isFalse);
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_misused_test_matchers: false
```
