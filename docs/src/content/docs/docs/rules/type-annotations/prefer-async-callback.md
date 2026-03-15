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

Flags uses of `Future<void> Function()` that can be replaced with the `AsyncCallback` typedef from `package:flutter/foundation.dart`. The typedef is shorter, more readable, and is the standard Flutter convention for no-argument async void callbacks.

## Why use this rule

`AsyncCallback` is a well-known typedef in the Flutter framework. Using it instead of the verbose `Future<void> Function()` makes code more concise and consistent with the rest of the Flutter ecosystem. The quick fix automatically replaces the type and adds the necessary import.

**See also:** [AsyncCallback typedef](https://api.flutter.dev/flutter/foundation/AsyncCallback.html)

## Don't

```dart
class BadWidget {
  final Future<void> Function() onTap;
  final Future<void> Function()? onLongPress;

  const BadWidget(this.onTap, this.onLongPress);
}

void badParameter(Future<void> Function() callback) {}

Future<void> Function() badReturnType() => () async {};

List<Future<void> Function()> callbacks = [];
```

## Do

```dart
class GoodWidget {
  final AsyncCallback onTap;
  final AsyncCallback? onLongPress;

  const GoodWidget(this.onTap, this.onLongPress);
}

// Function types with different return types or parameters are fine:
Future<int> Function() goodFutureInt = () async => 0;
Future<void> Function(int value) goodWithParams = (_) async {};
void Function() goodVoidCallback = () {};
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_async_callback: false
```
