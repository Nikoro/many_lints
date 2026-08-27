---
title: prefer_test_matchers
description: "Prefer using a Matcher instead of a literal value in expect()."
sidebar:
  label: prefer_test_matchers
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Testing Rules</span>

Flags an `expect()` or `expectLater()` call whose second argument is a plain value rather than a `Matcher`.

`expect(x, 1)` passes and fails correctly, but when it fails all it can say is `Expected: <1> Actual: <2>`. A matcher describes the assertion, so the failure names it.

## Don't

Each of these asserts the right thing and reports it badly:

```dart
void main() {
  test('keeps three scores', () {
    final scores = [7, 8, 9];

    expect(scores.length, 3);
    expect(scores, [7, 8, 9]);
    expect(scores.isEmpty, false);
  });
}
```

`expect(scores.length, 3)` failing prints `Expected: <3> Actual: <2>` — the
count, not the list. You then go and print the list by hand.

## Do

The same three assertions, said with matchers:

```dart
void main() {
  test('keeps three scores', () {
    final scores = [7, 8, 9];

    expect(scores, hasLength(3));
    expect(scores, equals([7, 8, 9]));
    expect(scores, isNotEmpty);
  });
}
```

Now the first one failing prints
`Expected: an object with length of <3> Actual: [7, 8]  Which: has length of <2>`.

### The everyday swaps

| Instead of | Write |
|------------|-------|
| `expect(value, 'hello')` | `expect(value, equals('hello'))` |
| `expect(flag, true)` | `expect(flag, isTrue)` |
| `expect(flag, false)` | `expect(flag, isFalse)` |
| `expect(result, null)` | `expect(result, isNull)` |
| `expect(items.length, 3)` | `expect(items, hasLength(3))` |
| `expect(items, [1, 2])` | `expect(items, equals([1, 2]))` |

```dart
void main() {
  test('parses a greeting', () {
    final value = 'hello';
    final result = null;
    final flag = true;

    expect(value, equals('hello'));
    expect(flag, isTrue);
    expect(result, isNull);
  });
}
```

### `expectLater` too

The rule reads the second argument of both functions:

```dart
void main() {
  test('resolves to three scores', () async {
    // Don't
    await expectLater(loadScores(), completion([7, 8, 9]));

    // Do
    await expectLater(loadScores(), completion(equals([7, 8, 9])));
  });
}

Future<List<int>> loadScores() async => [7, 8, 9];
```

### Never reported

A `Matcher` in any form satisfies the rule — including one held in a variable,
and `isA<T>()`:

```dart
void main() {
  test('accepts a matcher from a variable', () {
    final expected = equals(42);

    expect(1 + 41, expected);
    expect('hello', isA<String>());
  });
}
```

A `reason:` named argument is ignored, since the rule only reads the second
positional argument.

**See also:** [test package - Matchers](https://pub.dev/packages/test#matchers)

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

## Related rules

- [`avoid_misused_test_matchers`](/many_lints/docs/rules/testing-rules/avoid-misused-test-matchers/) — Detect test matchers used with incompatible value types.
- [`prefer_expect_later`](/many_lints/docs/rules/testing-rules/prefer-expect-later/) — Use 'expectLater' instead of 'expect' when testing Futures.
- [`format_test_name`](/many_lints/docs/rules/testing-rules/format-test-name/) — Hold test descriptions to a house pattern.
- [`prefer_correct_test_file_name`](/many_lints/docs/rules/testing-rules/prefer-correct-test-file-name/) — Name test files so the runner actually runs them.
