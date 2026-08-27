---
title: prefer_async_callback
description: "Use 'AsyncCallback' instead of 'Future<void> Function()'."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_async_callback
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Type Annotations</span>

Flags `Future<void> Function()` written where the `AsyncCallback` typedef from `package:flutter/foundation.dart` would say the same thing. The quick fix replaces the type and adds the import.

Only the exact shape is reported: no parameters, and a `Future<void>` return. `Future<int> Function()` and `Future<void> Function(int)` are left alone — there is no typedef for them.

## Don't

A callback field on a widget, spelled out longhand:

```dart
class UploadButton {
  const UploadButton({required this.onPressed, this.onCancel});

  final Future<void> Function() onPressed;
  final Future<void> Function()? onCancel;
}
```

The same type in a function signature and a return type:

```dart
void retryOnFailure(Future<void> Function() action) {}

Future<void> Function() saveDraftAction(String draftId) =>
    () async {};
```

And in a collection of pending work:

```dart
final List<Future<void> Function()> pendingUploads = [];
```

## Do

```dart
import 'package:flutter/foundation.dart';

class UploadButton {
  const UploadButton({required this.onPressed, this.onCancel});

  final AsyncCallback onPressed;
  final AsyncCallback? onCancel;
}

void retryOnFailure(AsyncCallback action) {}

AsyncCallback saveDraftAction(String draftId) => () async {};

final List<AsyncCallback> pendingUploads = [];
```

### Shapes that are never reported

`AsyncCallback` is exactly `Future<void> Function()`, so anything with a
parameter or a different return type has no typedef to swap in:

```dart
// A result to await, not just completion.
Future<int> Function() fetchCount = () async => 0;

// Takes an argument.
Future<void> Function(int index) removeAt = (_) async {};

// Synchronous — that one is `VoidCallback`; see prefer_void_callback.
void Function() dismiss = () {};
```

**See also:** [AsyncCallback typedef](https://api.flutter.dev/flutter/foundation/AsyncCallback.html)

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_async_callback: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_async_callback: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_void_callback`](/many_lints/docs/rules/type-annotations/prefer-void-callback/) — Use 'VoidCallback' instead of 'void Function()'.
- [`prefer_equatable_mixin`](/many_lints/docs/rules/type-annotations/prefer-equatable-mixin/) — Prefer using EquatableMixin instead of extending Equatable.
- [`prefer_explicit_function_type`](/many_lints/docs/rules/type-annotations/prefer-explicit-function-type/) — Prefer explicit function type annotations over the bare 'Function' type.
- [`prefer_explicit_parameter_names`](/many_lints/docs/rules/type-annotations/prefer-explicit-parameter-names/) — Name the parameters of a function type.
