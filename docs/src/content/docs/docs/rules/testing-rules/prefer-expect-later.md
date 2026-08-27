---
title: prefer_expect_later
description: "Use 'expectLater' instead of 'expect' when testing Futures."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_expect_later
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Testing Rules</span>

Flags `expect()` calls where the first argument is a `Future`. Passing a Future to `expect()` instead of `expectLater()` means the assertion completes before the asynchronous operation finishes, causing the test to silently pass regardless of the actual result.

## Why use this rule

Using `expect()` with a Future is almost always a bug. The test framework cannot await a synchronous `expect()` call, so the assertion is evaluated against the Future object itself rather than its resolved value. Switching to `await expectLater()` ensures the Future completes before the matcher runs.

**See also:** [test package - expectLater](https://pub.dev/documentation/test/latest/test/expectLater.html)

## Don't

```dart
void main() {
  test('loads the cart', () {
    expect(loadCart(), completion(isNotNull));

    final total = cartTotal();
    expect(total, completion(equals(240)));
  });
}
```

Nothing awaits the assertion, so the test ends before the future resolves and
passes whatever the future produces.

## Do

```dart
void main() {
  test('loads the cart', () async {
    await expectLater(loadCart(), completion(isNotNull));

    final total = cartTotal();
    await expectLater(total, completion(equals(240)));
  });
}
```

Matching a plain value needs no change — `expect` is only a problem when the
actual value is a `Future`:

```dart
void main() {
  test('sums the lines', () {
    expect(subtotal(), equals(240));
  });
}
```

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_expect_later: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_misused_test_matchers`](/many_lints/docs/rules/testing-rules/avoid-misused-test-matchers/) — Detect test matchers used with incompatible value types.
- [`prefer_test_matchers`](/many_lints/docs/rules/testing-rules/prefer-test-matchers/) — Prefer using a Matcher instead of a literal value in expect().
- [`avoid_focused_tests`](/many_lints/docs/rules/testing-rules/avoid-focused-tests/) — Detect tests focused with solo:, which silences their siblings.
- [`avoid_skipped_tests`](/many_lints/docs/rules/testing-rules/avoid-skipped-tests/) — Detect tests, groups and libraries switched off in place.
