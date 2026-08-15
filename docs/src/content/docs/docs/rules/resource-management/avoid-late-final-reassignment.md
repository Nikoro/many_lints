---
title: avoid_late_final_reassignment
description: "Flag a `late final` field assigned twice on one path"
sidebar:
  label: avoid_late_final_reassignment
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Resource Management</span>

This rule flags a `late final` field assigned more than once on the same straight-line path.

## Why use this rule

`late final` promises one assignment, and Dart enforces it — but at run time, by throwing `LateInitializationError` on the second write. A second assignment the analyzer can see on one path is therefore a guaranteed crash, not a possibility, and it is worth catching before the code runs.

Only assignments in the same block are compared, without following branches. Two writes in opposite arms of an `if` are exactly how a `late final` is meant to be initialised, so they are left alone.

**See also:** [`late` variables](https://dart.dev/language/variables#late-variables)

## Don't

```dart
class Session {
  late final String token;

  void start(String value) {
    token = value;
    token = value.trim(); // throws LateInitializationError
  }
}
```

## Do

```dart
class Session {
  late final String token;

  void start(String value) {
    token = value.trim();
  }
}
```

Initialising through branches is fine:

```dart
class Session {
  late final String token;

  void start(bool isGuest) {
    if (isGuest) {
      token = 'guest';
    } else {
      token = generate();
    }
  }
}
```

## Turning this rule off

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_late_final_reassignment: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
