---
title: avoid_unnecessary_call
description: "Invoke a function directly instead of through .call()"
sidebar:
  label: avoid_unnecessary_call
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags a function invoked through an explicit `.call()`.

## Why use this rule

`callback.call()` and `callback()` do the same thing, and the shorter one is how a function is invoked everywhere else in the language. Spelling out `.call` makes a plain invocation look like a method on an object, so a reader stops to check whether the receiver is a callable class.

Two cases are left alone. A null-aware invocation (`callback?.call()`) has no shorthand — `callback?()` does not parse. And a class defining `call` as a real method is invoking *that* method, where `.call` is part of its name rather than the implicit function interface; the rule checks the receiver's type to tell the two apart.

## Don't

```dart
void submit(void Function() onDone) {
  onDone.call();
}
```

## Do

```dart
void submit(void Function() onDone) {
  onDone();
}
```

## Turning this rule off

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_call: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
