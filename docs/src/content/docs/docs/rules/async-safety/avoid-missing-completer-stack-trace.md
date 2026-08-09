---
title: avoid_missing_completer_stack_trace
description: "Pass the stack trace to Completer.completeError"
sidebar:
  label: avoid_missing_completer_stack_trace
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule flags a `Completer.completeError(e)` call inside a catch block that binds a stack trace but does not pass it on. The trace is available right there, and dropping it makes the resulting error much harder to diagnose.

## Why use this rule

`completeError` takes an optional second argument, the stack trace. When it is omitted, the error still propagates, but the trace attached to it starts where the future was *completed* rather than where the failure actually occurred.

In practice that means the exception surfaces at the `await` with a stack that points into async plumbing, and the line that actually threw is gone. The information was in scope — `catch (e, st)` bound it — and simply not forwarded.

By default the rule only reports inside a catch clause that binds a stack-trace variable. That is the case where the fix is unambiguous: something to pass exists and is being discarded.

**See also:** [dart:async Completer.completeError](https://api.dart.dev/stable/dart-async/Completer/completeError.html)

## Don't

```dart
try {
  await doWork();
} catch (e, st) {
  completer.completeError(e);   // `st` is discarded
}
```

## Do

```dart
try {
  await doWork();
} catch (e, st) {
  completer.completeError(e, st);
}
```

## Known limitations

A bare `catch (e)` with no stack-trace parameter is not reported: nothing is in scope to pass, so the report would be unactionable. Widen with `require_inside_catch: false` if you want every call site flagged.

A `completeError` inside a closure declared within the catch block is not reported either. The closure runs on its own schedule and cannot be assumed to still have meaningful access to the enclosing trace.

Matching is by static type, so any subtype of `Completer` is covered, and a same-named `completeError` on an unrelated class is not.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_missing_completer_stack_trace: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  avoid_missing_completer_stack_trace:
    require_inside_catch: false
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `require_inside_catch` | bool | `true` | Only report inside a catch clause that binds a stack trace. Set to `false` to flag every `completeError` call with a single argument |

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
