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

Flags an `expect()` call whose **first** argument is a `Future`. Nothing awaits a plain `expect`, so the test method returns before the future resolves and the assertion's outcome is never seen.

## Don't

`loadCart()` returns a `Future`. The test body is synchronous, so it finishes
immediately and passes whatever the future eventually produces — including a
failure:

```dart
void main() {
  test('loads the cart', () {
    expect(loadCart(), completion(isNotNull));
  });
}

Future<Object?> loadCart() async => null;
```

The same hole when the future is held in a variable first — the rule reads the
static type, not the shape of the expression:

```dart
void main() {
  test('totals the cart', () {
    final total = cartTotal();
    expect(total, completion(equals(240)));
  });
}

Future<int> cartTotal() async => 240;
```

## Do

`await expectLater(...)` in an `async` body. The test now waits for the future
and the matcher runs against its value:

```dart
void main() {
  test('loads the cart', () async {
    await expectLater(loadCart(), completion(isNotNull));
  });

  test('totals the cart', () async {
    final total = cartTotal();
    await expectLater(total, completion(equals(240)));
  });
}

Future<Object?> loadCart() async => null;
Future<int> cartTotal() async => 240;
```

Awaiting the value instead is equally correct, and often reads better — the
matcher then describes the resolved value rather than the future:

```dart
void main() {
  test('totals the cart', () async {
    expect(await cartTotal(), equals(240));
  });
}

Future<int> cartTotal() async => 240;
```

### Never reported

`expect` is only a problem when the actual value is a `Future`. A plain value
needs no change:

```dart
void main() {
  test('sums the lines', () {
    expect(subtotal(), equals(240));
  });
}

int subtotal() => 240;
```

The rule also reports `expect` only — an `expectLater` you already wrote is
left alone, awaited or not.

**See also:** [test package - expectLater](https://pub.dev/documentation/test/latest/test/expectLater.html)

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
