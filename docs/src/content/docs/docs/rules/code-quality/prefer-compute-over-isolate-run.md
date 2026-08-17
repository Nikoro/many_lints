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
<span class="rule-badge rule-badge--category">Code Quality</span>

Flags uses of `Isolate.run()` from `dart:isolate`, which is not supported on the web platform. Flutter's `compute()` function from `package:flutter/foundation.dart` provides the same background execution capability while working across all platforms including web.

## Why use this rule

`Isolate.run()` throws at runtime on web targets because web browsers do not support Dart isolates. By using `compute()` instead, your code works on mobile, desktop, and web without any platform-specific conditional logic.

**See also:** [Flutter - compute()](https://api.flutter.dev/flutter/foundation/compute.html) | [Dart - Isolate.run()](https://api.dart.dev/stable/dart-isolate/Isolate/run.html)

## Don't

```dart
import 'dart:isolate';

Future<void> runWork() async {
  final result = await Isolate.run(() => expensiveWork());
  final result2 = await Isolate.run(() async => expensiveWork());
  final result3 = await Isolate.run(expensiveWork);
  final result4 = await Isolate.run<int>(() => expensiveWork());
}
```

## Do

```dart
import 'package:flutter/foundation.dart';

Future<void> runWork() async {
  final result = await compute((_) => expensiveWork(), null);
}
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_compute_over_isolate_run: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_compute_over_isolate_run: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
- [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/) — Detect and flag commented-out code.
- [`avoid_complex_conditions`](/many_lints/docs/rules/code-quality/avoid-complex-conditions/) — Keep boolean conditions within an operand budget.
- [`avoid_deep_nesting`](/many_lints/docs/rules/code-quality/avoid-deep-nesting/) — Keep control flow within a nesting budget.
