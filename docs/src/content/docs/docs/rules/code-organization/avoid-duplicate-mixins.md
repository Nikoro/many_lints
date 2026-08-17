---
title: avoid_duplicate_mixins
description: "Flag a mixin applied twice in one `with` clause"
sidebar:
  label: avoid_duplicate_mixins
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Organization</span>

This rule flags a `with` clause that lists the same mixin more than once, where every application after the first contributes nothing.

## Why use this rule

`class A with M, M {}` compiles, and the second `M` adds no members — they are already there. What it does add is a false signal: a reader counting the behaviours mixed into `A` sees one more than exists, and has to check whether the two entries differ before concluding they do not.

Duplicates arrive through merges, and through a rename that collapses two once-distinct names onto one.

The rule compares resolved types, not source text, so an aliased import (`M` and `alias.M`) still counts as one mixin. Type arguments are kept, so a genuinely different instantiation is not reported.

Re-applying a mixin that a superclass already has is a different question — it does change the linearization order — so it is not reported.

**See also:** [Mixins](https://dart.dev/language/mixins)

## Don't

```dart
mixin Loggable {}

class Report with Loggable, Loggable {}
```

## Do

```dart
mixin Loggable {}
mixin Cacheable {}

class Report with Loggable, Cacheable {}
```

## Turning this rule off

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`.

To disable this rule:

```yaml
# many_lints.yaml
rules:
  avoid_duplicate_mixins: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`arguments_ordering`](/many_lints/docs/rules/code-organization/arguments-ordering/) — Keep named arguments in a configured order.
- [`avoid_generics_shadowing`](/many_lints/docs/rules/code-organization/avoid-generics-shadowing/) — Avoid generic type parameters that shadow top-level declarations.
- [`avoid_unnecessary_constructor`](/many_lints/docs/rules/code-organization/avoid-unnecessary-constructor/) — Remove a constructor identical to the default one.
- [`avoid_unnecessary_extends`](/many_lints/docs/rules/code-organization/avoid-unnecessary-extends/) — Remove an explicit `extends Object`.
