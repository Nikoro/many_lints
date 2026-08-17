---
title: prefer_void_callback
description: "Use 'VoidCallback' instead of 'void Function()'."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_void_callback
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Type Annotations</span>

Flags uses of `void Function()` that can be replaced with the `VoidCallback` typedef from `dart:ui`. The typedef is shorter, more readable, and is the standard Flutter convention for no-argument void callbacks.

## Why use this rule

`VoidCallback` is a well-known typedef in the Flutter framework. Using it instead of the verbose `void Function()` makes code more concise and consistent with the rest of the Flutter ecosystem. The quick fix automatically replaces the type and adds the necessary import.

**See also:** [VoidCallback typedef](https://api.flutter.dev/flutter/dart-ui/VoidCallback.html)

## Don't

```dart
class BadWidget {
  final void Function() onTap;
  final void Function()? onLongPress;

  const BadWidget(this.onTap, this.onLongPress);
}

void badParameter(void Function() callback) {}

void Function() badReturnType() => () {};

List<void Function()> callbacks = [];
```

## Do

```dart
class GoodWidget {
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const GoodWidget(this.onTap, this.onLongPress);
}

// Function types with parameters or different return types are fine:
void goodWithParams(void Function(int value) callback) {}
int Function() goodIntReturn = () => 0;
Future<void> Function() goodFutureReturn = () async {};
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_void_callback: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_void_callback: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_explicit_function_type`](/many_lints/docs/rules/type-annotations/prefer-explicit-function-type/) — Prefer explicit function type annotations over the bare 'Function' type.
- [`prefer_explicit_parameter_names`](/many_lints/docs/rules/type-annotations/prefer-explicit-parameter-names/) — Name the parameters of a function type.
- [`prefer_typedefs_for_callbacks`](/many_lints/docs/rules/type-annotations/prefer-typedefs-for-callbacks/) — Name a multi-parameter function type with a typedef.
- [`prefer_async_callback`](/many_lints/docs/rules/type-annotations/prefer-async-callback/) — Use 'AsyncCallback' instead of 'Future&lt;void&gt; Function()'.
