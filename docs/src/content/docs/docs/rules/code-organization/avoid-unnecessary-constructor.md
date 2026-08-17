---
title: avoid_unnecessary_constructor
description: "Remove a constructor identical to the default one"
sidebar:
  label: avoid_unnecessary_constructor
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Organization</span>

This rule flags an empty unnamed constructor that matches the one Dart provides when no constructor is declared at all.

## Why use this rule

`class A { A(); }` writes out exactly the default: no parameters, no initializers, no body, no documentation. The line adds nothing a reader can act on, and it invites the assumption that construction does something.

Several shapes are deliberately **not** reported, because each does something the implicit constructor cannot:

- `const A();` — lets callers write `const A()`.
- A named or private constructor.
- A documented or annotated one, which carries information even when empty.
- Any class with a second constructor: Dart only supplies the unnamed one when **no** constructor is written, so there the empty `A()` is what keeps `A()` legal.

## Don't

```dart
class Repository {
  Repository();
}
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
      avoid_unnecessary_constructor: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`arguments_ordering`](/many_lints/docs/rules/code-organization/arguments-ordering/) — Keep named arguments in a configured order.
- [`avoid_duplicate_mixins`](/many_lints/docs/rules/code-organization/avoid-duplicate-mixins/) — Flag a mixin applied twice in one `with` clause.
- [`avoid_generics_shadowing`](/many_lints/docs/rules/code-organization/avoid-generics-shadowing/) — Avoid generic type parameters that shadow top-level declarations.
- [`avoid_unnecessary_extends`](/many_lints/docs/rules/code-organization/avoid-unnecessary-extends/) — Remove an explicit `extends Object`.
