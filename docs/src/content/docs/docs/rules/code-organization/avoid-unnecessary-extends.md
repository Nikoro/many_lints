---
title: avoid_unnecessary_extends
description: "Remove an explicit `extends Object`"
sidebar:
  label: avoid_unnecessary_extends
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Organization</span>

This rule flags a class that explicitly extends `Object`.

## Why use this rule

Every Dart class extends `Object` already, so the clause states the default while looking like a decision. A reader who sees an `extends` expects the superclass to matter, and has to recall that this one does not.

A class extending a *user-declared* `Object` that shadows `dart:core`'s is making a real choice, and is left alone.

**See also:** [`Object`](https://api.dart.dev/stable/dart-core/Object-class.html)

## Don't

```dart
class Repository extends Object {}
```

## Do

```dart
class Repository {}
```

## Turning this rule off

This rule is in the **`opinionated`** preset.

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_extends: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`arguments_ordering`](/many_lints/docs/rules/code-organization/arguments-ordering/) — Keep named arguments in a configured order.
- [`avoid_duplicate_mixins`](/many_lints/docs/rules/code-organization/avoid-duplicate-mixins/) — Flag a mixin applied twice in one `with` clause.
- [`avoid_generics_shadowing`](/many_lints/docs/rules/code-organization/avoid-generics-shadowing/) — Avoid generic type parameters that shadow top-level declarations.
- [`avoid_unnecessary_constructor`](/many_lints/docs/rules/code-organization/avoid-unnecessary-constructor/) — Remove a constructor identical to the default one.
