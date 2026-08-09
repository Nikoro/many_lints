---
title: avoid_shadowed_extension_methods
description: "An extension member the extended type already has"
sidebar:
  label: avoid_shadowed_extension_methods
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags an extension member whose name already exists on the type being extended. Instance members always win over extension members, so the extension one can never be called.

## Why use this rule

Extension members are resolved statically and lose to instance members every time. An extension declaring `toUpperCase()` on `String` compiles cleanly and is simply never invoked — every call site silently reaches `String.toUpperCase` instead.

The result is code that reads as though the extension applies and behaves as though it does not. Since nothing errors, the discrepancy is usually found by debugging the wrong thing.

**See also:** [Dart: extension methods](https://dart.dev/language/extension-methods#static-types-and-dynamic-types)

## Don't

```dart
extension on String {
  String toUpperCase() => '!';   // never called
}
```

## Do

Give the extension member a name the type does not already use:

```dart
extension on String {
  String shout() => '\$this!';
}
```

## Known limitations

The check walks the extended type and its supertypes. Members inherited from `Object` are excluded — every type has them, so reporting `toString` or `hashCode` would flag ordinary, useful extensions.

Static extension members are skipped, since they are accessed through the extension name and cannot be shadowed.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_shadowed_extension_methods: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
