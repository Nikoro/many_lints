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

**See also:** [test package - expectLater](https://pub.dev/documentation/test_api/latest/test_api/expectLater.html)

## Don't

```dart
Future<void> bad() async {
  expect(Future.value(1), completion);

  final future = Future.value(42);
  expect(future, completion);

  expect(fetchData(), completion);
}
```

## Do

```dart
Future<void> good() async {
  await expectLater(Future.value(1), completion);

  final future = Future.value(42);
  await expectLater(future, completion);

  // expect with non-Future values is fine:
  expect(42, completion);
  expect('hello', completion);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_expect_later: false
```
