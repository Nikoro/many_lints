---
title: avoid_unnecessary_enum_prefix
description: "Drop an enum name repeated in its own constants"
sidebar:
  label: avoid_unnecessary_enum_prefix
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Class Naming</span>

This rule flags an enum constant that repeats the name of its own enum.

## Why use this rule

`enum Status { statusActive }` reads as `Status.statusActive` at every call site, where the type already says `Status`. The prefix is a habit carried over from languages whose enum constants share one namespace; Dart scopes them to the enum, so it buys nothing and lengthens every use.

Dropping it also makes dot shorthands read properly: `.active` rather than `.statusActive`.

Two shapes are deliberately not reported: a constant named exactly like its enum (`Status.status` is the whole word, not a prefix), and one that merely starts with the same letters (`statusable`), since the prefix has to end at a word boundary.

**See also:** [Enumerated types](https://dart.dev/language/enums)

## Don't

```dart
enum Status {
  statusActive,
  statusArchived,
}

// Every use repeats the type name.
final state = Status.statusActive;
```

## Do

```dart
enum Status {
  active,
  archived,
}

final state = Status.active;
```

## Turning this rule off

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_enum_prefix: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
