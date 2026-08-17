---
title: prefer_primary_constructors
description: "Prefer a primary constructor (Dart 3.13+) over a class of final fields plus a field-assigning constructor."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_primary_constructors
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

Warns when a class consists only of final fields and a constructor that does nothing but assign them. Since Dart 3.13, primary constructors let the whole declaration collapse into the class header, so the field list, the constructor signature and the assignments stop being three copies of the same information.

## Why use this rule

A value class written the old way names each field three times: once in the field declaration, once in the constructor parameter list, and once implicitly in the assignment. Dart 3.13 makes primary constructors stable, so `class Point(final int x, final int y);` declares the fields, the constructor and the assignments at once. Fewer places to edit means the three can never drift out of sync — the classic bug where a new field is added but the constructor is not updated simply stops being expressible.

The rule is deliberately conservative. It only reports a class whose **entire** body is those final fields plus that one constructor, because only those collapse to the `;` form with nothing left behind. A class with a method, a getter, a static member, a second constructor, an initializer list, a constructor body, a superclass, or a mutable field is left alone.

This does **not** overlap with the SDK's `use_declaring_parameters`. That rule visits primary-constructor nodes only, so it never fires on a class that has yet to adopt one — it polishes classes that already migrated, while this rule is what suggests migrating in the first place. Note that the SDK's `unnecessary_type_name_in_constructor` does fire on the same classes, suggesting the weaker `new(this.x)` form; if you adopt this rule, you will likely want that one off.

**See also:** [Announcing Dart 3.13](https://dart.dev/blog/announcing-dart-3-13) | [Primary constructors feature specification](https://github.com/dart-lang/language/blob/main/accepted/3.13/primary-constructors/feature-specification.md)

## Don't

```dart
// LINT: the fields, the parameters and the assignments are three copies
// of the same list.
class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}
```

## Do

```dart
class Point(final int x, final int y);
```

`const` moves onto the class header, where instances stay const-constructible:

```dart
class const Point(final int x, final int y);
```

## Not reported

The rule stays silent whenever the class would still need a body:

```dart
// Has a getter, so the body survives.
class WithMethod {
  final int v;
  WithMethod(this.v);
  int get doubled => v * 2;
}

// The initializer list does work beyond assigning fields.
class Guarded {
  final int x;
  Guarded(this.x) : assert(x > 0);
}
```

## Quick fix

The fix rewrites the header and replaces the body with `;`, keeping the **constructor's** parameter order rather than the field declaration order — reordering would silently break every positional call site. It preserves `const`, type parameters, `required`, named-parameter braces and default values.

It deliberately declines when a field carries a doc comment or an annotation: neither has a home in a parameter list, and dropping documentation silently is worse than leaving the diagnostic for you to handle.

## Turning this rule off

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_primary_constructors: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_primary_constructors: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
- [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/) — Detect and flag commented-out code.
- [`avoid_complex_conditions`](/many_lints/docs/rules/code-quality/avoid-complex-conditions/) — Keep boolean conditions within an operand budget.
- [`avoid_deep_nesting`](/many_lints/docs/rules/code-quality/avoid-deep-nesting/) — Keep control flow within a nesting budget.
