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

Flags `void Function()` written where the `VoidCallback` typedef from `dart:ui` would say the same thing. The quick fix replaces the type and adds the import.

Only the exact shape is reported: no parameters, and a `void` return. `void Function(int)` and `int Function()` are left alone — there is no typedef for them.

## Don't

A callback field on a widget, spelled out longhand:

```dart
class DismissButton {
  const DismissButton({required this.onPressed, this.onLongPress});

  final void Function() onPressed;
  final void Function()? onLongPress;
}
```

The same type in a function signature and a return type:

```dart
void onNextFrame(void Function() callback) {}

void Function() dismissAction(String routeName) => () {};
```

And in a collection of teardown work:

```dart
final List<void Function()> disposers = [];
```

## Do

```dart
import 'dart:ui';

class DismissButton {
  const DismissButton({required this.onPressed, this.onLongPress});

  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
}

void onNextFrame(VoidCallback callback) {}

VoidCallback dismissAction(String routeName) => () {};

final List<VoidCallback> disposers = [];
```

In a Flutter file `VoidCallback` usually needs no import of its own — it is
re-exported by `package:flutter/foundation.dart` and by `material.dart`.

### Shapes that are never reported

`VoidCallback` is exactly `void Function()`, so anything with a parameter or a
different return type has no typedef to swap in:

```dart
// Takes an argument — that family is `ValueChanged<T>`.
void Function(int index) onSelected = (_) {};

// Returns a value.
int Function() itemCount = () => 0;

// Asynchronous — that one is `AsyncCallback`; see prefer_async_callback.
Future<void> Function() refresh = () async {};
```

**See also:** [VoidCallback typedef](https://api.flutter.dev/flutter/dart-ui/VoidCallback.html)

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
