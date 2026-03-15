---
title: prefer_compute_over_isolate_run
description: "Use 'compute()' instead of 'Isolate.run()' for web platform compatibility."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_compute_over_isolate_run
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Testing Rules</span>

Flags uses of `Isolate.run()` from `dart:isolate`, which is not supported on the web platform. Flutter's `compute()` function from `package:flutter/foundation.dart` provides the same background execution capability while working across all platforms including web.

## Why use this rule

`Isolate.run()` throws at runtime on web targets because web browsers do not support Dart isolates. By using `compute()` instead, your code works on mobile, desktop, and web without any platform-specific conditional logic.

**See also:** [Flutter - compute()](https://api.flutter.dev/flutter/foundation/compute.html) | [Dart - Isolate.run()](https://api.dart.dev/stable/dart-isolate/Isolate/run.html)

## Don't

```dart
import 'dart:isolate';

final result = await Isolate.run(() => expensiveWork());
final result2 = await Isolate.run(() async => expensiveWork());
final result3 = await Isolate.run(expensiveWork);
final result4 = await Isolate.run<int>(() => expensiveWork());
```

## Do

```dart
import 'package:flutter/foundation.dart';

final result = await compute((_) => expensiveWork(), null);
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_compute_over_isolate_run: false
```
