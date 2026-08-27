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

`Isolate.run()` throws at runtime on web targets, because browsers do not support Dart isolates. `compute()` gives the same background execution and works on mobile, desktop and web, with no platform-specific branching.

**See also:** [Flutter - compute()](https://api.flutter.dev/flutter/foundation/compute.html) | [Dart - Isolate.run()](https://api.dart.dev/stable/dart-isolate/Isolate/run.html)

## Don't

Parsing a large payload off the UI thread — correct everywhere except in the browser:

```dart
import 'dart:isolate';

class ReportParser {
  Future<int> parse(String csv) async {
    return Isolate.run(() => _countRows(csv));
  }

  static int _countRows(String csv) => csv.split('\n').length;
}
```

## Do

`compute()` takes a one-argument callback and its message, so the closure gains a parameter. The quick fix does this rewrite for you and adds the `foundation.dart` import:

```dart
import 'package:flutter/foundation.dart';

class ReportParser {
  Future<int> parse(String csv) async {
    return compute((_) => _countRows(csv), null);
  }

  static int _countRows(String csv) => csv.split('\n').length;
}
```

Better still, pass the payload as the message so nothing is captured by the closure:

```dart
import 'package:flutter/foundation.dart';

class ReportParser {
  Future<int> parse(String csv) => compute(_countRows, csv);

  static int _countRows(String csv) => csv.split('\n').length;
}
```

### What the quick fix does to each callback shape

| You wrote | The fix produces |
|-----------|------------------|
| `Isolate.run(() => work())` | `compute((_) => work(), null)` |
| `Isolate.run(() async => work())` | `compute((_) async => work(), null)` |
| `Isolate.run(() { ... })` | `compute((_) { ... }, null)` |
| `Isolate.run(work)` | `compute((_) => work(), null)` |

## Known limitations

**Only `Isolate.run` is reported**, and only when `Isolate` resolves to `dart:isolate`. A class of your own named `Isolate` is left alone.

**Other isolate APIs are not covered.** `Isolate.spawn`, `ReceivePort` and friends have no `compute` equivalent and are never reported.

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
