---
title: prefer_test_matchers
description: "Prefer using a Matcher instead of a literal value in expect()."
sidebar:
  label: prefer_test_matchers
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Testing Rules</span>

Flags `expect()` and `expectLater()` calls where the second argument is a raw literal value instead of a `Matcher` subclass. Using raw literals like `expect(x, 1)` produces less informative failure messages than using matchers like `expect(x, equals(1))`.

## Why use this rule

When a test fails, matchers provide descriptive output such as "Expected: has length of 3 / Actual: [1, 2]" instead of just "Expected: 3 / Actual: 2". This makes debugging faster. Using matchers also enables richer assertions like `hasLength()`, `contains()`, and `isA<T>()` that raw values cannot express.

**See also:** [test package - Matchers](https://pub.dev/packages/test#matchers)

## Don't

```dart
expect(scores.length, 1);
expect(value, 'hello');
expect(true, true);
expect(scores, [7, 8, 9]);
expect(maybeNull, null);
expectLater(scores.length, 1);
```

## Do

```dart
expect(scores, hasLength(1));
expect(value, equals('hello'));
expect(true, isTrue);
expect(scores, equals([7, 8, 9]));
expect(maybeNull, isNull);
expect(value, isA<String>());
expectLater(scores, hasLength(3));
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_test_matchers: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_test_matchers: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
