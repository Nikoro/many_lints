---
title: avoid_misused_test_matchers
description: "Detect test matchers used with incompatible value types."
sidebar:
  label: avoid_misused_test_matchers
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Testing Rules</span>

Flags an `expect()` call whose matcher cannot possibly agree with the actual value's static type — `isNull` on a non-nullable `int`, `isEmpty` on a number, `isList` on a `String`.

A mismatched matcher does not fail loudly. Half of them always fail, so the assertion is useless; the other half always pass, so the test looks like coverage while asserting nothing.

## Don't

Each of these is decided by the type before the test even runs:

```dart
void main() {
  test('reports a total', () {
    final total = 42;

    expect(total, isNotNull);      // always true — `int` cannot be null
    expect(total, isNull);         // always false — same reason
    expect(total, isEmpty);        // `int` has no isEmpty
    expect(total, hasLength(1));   // `int` has no length
    expect(total, isTrue);         // `int` is not a bool
  });
}
```

The `isNotNull` line is the dangerous one: it passes, so the test is green and
nobody looks at it again.

The mirror mistakes, on a `String`:

```dart
void main() {
  test('reports a label', () {
    final label = 'hello';

    expect(label, isList);   // String is not a List
    expect(label, isMap);    // String is not a Map
    expect(label, isZero);   // String is not a num
  });
}
```

## Do

Assert the thing the type can actually be:

```dart
void main() {
  test('reports a total', () {
    final total = 42;

    expect(total, equals(42));
    expect(total, isPositive);
    expect(total, isNot(isZero));
  });

  test('reports a label', () {
    final label = 'hello';

    expect(label, isNotEmpty);
    expect(label, hasLength(5));
    expect(label, equals('hello'));
  });
}
```

### Nullability matchers need a nullable type

`isNull` and `isNotNull` are only meaningful where `null` is possible:

```dart
void main() {
  test('returns null for a missing key', () {
    // Don't — `int` is non-nullable, so this can never be null.
    final present = 1;
    expect(present, isNull);

    // Do — the type admits null, so the assertion says something.
    final int? missing = null;
    expect(missing, isNull);
  });
}
```

### The pairings the rule knows

| Matcher | Actual value must be |
|---------|----------------------|
| `isNull`, `isNotNull` | a nullable type |
| `isEmpty`, `isNotEmpty` | `String`, `Iterable` or `Map` |
| `hasLength(n)` | `String`, `Iterable` or `Map` |
| `isList` | a `List` |
| `isMap` | a `Map` |
| `isZero`, `isNaN`, `isPositive`, `isNegative` | a `num` |
| `isTrue`, `isFalse` | a `bool` |

Anything not in this table — `equals`, `contains`, `isA<T>`, `throwsA`, a
matcher of your own — is never reported.

### Never reported

A value whose static type is `dynamic` is never reported: the rule cannot know
what it holds, and guessing would produce false positives on exactly the tests
that need the flexibility.

```dart
void main() {
  test('accepts a dynamic payload', () {
    final dynamic payload = 42;
    expect(payload, isEmpty);   // not reported — type is dynamic
  });
}
```

**See also:** [test package - Matchers](https://pub.dev/packages/test#matchers)

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_misused_test_matchers: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_test_matchers`](/many_lints/docs/rules/testing-rules/prefer-test-matchers/) — Prefer using a Matcher instead of a literal value in expect().
- [`prefer_expect_later`](/many_lints/docs/rules/testing-rules/prefer-expect-later/) — Use 'expectLater' instead of 'expect' when testing Futures.
- [`format_test_name`](/many_lints/docs/rules/testing-rules/format-test-name/) — Hold test descriptions to a house pattern.
- [`prefer_correct_test_file_name`](/many_lints/docs/rules/testing-rules/prefer-correct-test-file-name/) — Name test files so the runner actually runs them.
