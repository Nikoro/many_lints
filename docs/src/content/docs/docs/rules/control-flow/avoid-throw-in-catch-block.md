---
title: avoid_throw_in_catch_block
description: "Detect throw expressions inside catch blocks"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_throw_in_catch_block
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Flags a `throw` inside a `catch` block. The new exception starts a fresh stack trace at the `throw`, so the report points at the error handler instead of at the line that actually failed. Use `rethrow`, or `Error.throwWithStackTrace` when you want to change the exception type.

**See also:** [Exceptions](https://dart.dev/language/error-handling) | [Dart lint: throw_in_finally](https://dart.dev/tools/linter-rules/throw_in_finally) | [Dart lint: only_throw_errors](https://dart.dev/tools/linter-rules/only_throw_errors)

## Don't

Translating a low-level failure into a domain exception is the right instinct — but a bare `throw` throws away the only thing that says where it came from:

```dart
Future<Order> loadOrder(String id) async {
  try {
    return await fetchOrder(id);
  } on Object {
    throw OrderUnavailable(id);
  }
}

Future<Order> fetchOrder(String id) async => Order();

class Order {}

class OrderUnavailable implements Exception {
  OrderUnavailable(this.id);

  final String id;
}
```

## Do

Keep the wrapper *and* the trace by passing the caught stack explicitly:

```dart
Future<Order> loadOrder(String id) async {
  try {
    return await fetchOrder(id);
  } catch (error, stack) {
    Error.throwWithStackTrace(OrderUnavailable(id), stack);
  }
}

Future<Order> fetchOrder(String id) async => Order();

class Order {}

class OrderUnavailable implements Exception {
  OrderUnavailable(this.id);

  final String id;
}
```

### Forwarding the same exception

`throw e` re-throws the caught object but restarts the trace at the `throw`. `rethrow` keeps the original:

```dart
void demo(String id) {
  // Don't
  try {
    fetchOrderSync(id);
  } catch (e) {
    print(e);
    throw e;
  }
}

void fetchOrderSync(String id) {}
```

```dart
void demo(String id) {
  // Do
  try {
    fetchOrderSync(id);
  } catch (e) {
    print(e);
    rethrow;
  }
}

void fetchOrderSync(String id) {}
```

### A throw inside a closure is fine

The rule does not descend into nested functions, because a `throw` there runs whenever the closure is called — not while the catch block is unwinding:

```dart
void demo(String id) {
  try {
    fetchOrderSync(id);
  } catch (e) {
    scheduleRetry(() {
      throw StateError('retry gave up');   // Not reported
    });
  }
}

void fetchOrderSync(String id) {}

void scheduleRetry(void Function() action) {}
```

## Known limitations

Every `throw` reachable in the catch body is reported, however deeply nested in `if`, `for`, or `switch` — but never one inside a closure or a local function declaration.

The rule looks at `catch` and `on` clauses only. A `throw` in a `finally` block is a separate problem, covered by the SDK's [`throw_in_finally`](https://dart.dev/tools/linter-rules/throw_in_finally).

The quick fix rewrites `throw X` to `Error.throwWithStackTrace(X, stackTrace)`, adding the stack-trace parameter to the clause when it does not already have one — `catch (e)` becomes `catch (e, stackTrace)`, and a bare `on FormatException {` becomes `on FormatException catch (_, stackTrace) {`. When the thrown expression is the caught exception itself, plain `rethrow` is shorter and says the same thing; the fix does not choose it for you.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_throw_in_catch_block: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_throw_in_catch_block: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_empty_catch`](/many_lints/docs/rules/control-flow/avoid-empty-catch/) — Detect catch clauses that silently discard the failure.
- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
