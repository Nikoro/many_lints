---
title: avoid_late_final_reassignment
description: "Flag a `late final` field assigned twice on one path"
sidebar:
  label: avoid_late_final_reassignment
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Resource Management</span>

This rule flags a `late final` field assigned more than once on the same straight-line path.

This rule is in the **`core`** preset.

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
# many_lints.yaml
rules:
  avoid_late_final_reassignment: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`always_remove_listener`](/many_lints/docs/rules/resource-management/always-remove-listener/) — Ensure every addListener() has a matching removeListener() in dispose().
- [`avoid_unassigned_stream_subscriptions`](/many_lints/docs/rules/resource-management/avoid-unassigned-stream-subscriptions/) — Ensure stream subscriptions are assigned to a variable for proper cancellation.
- [`avoid_unremovable_callbacks_in_listeners`](/many_lints/docs/rules/resource-management/avoid-unremovable-callbacks-in-listeners/) — Don't pass an inline closure to addListener.
- [`dispose_fields`](/many_lints/docs/rules/resource-management/dispose-fields/) — Ensure State fields with disposal methods are cleaned up in dispose().
