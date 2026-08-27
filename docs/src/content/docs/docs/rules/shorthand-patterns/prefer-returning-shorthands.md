---
title: prefer_returning_shorthands
description: "Use dot shorthand constructors in expression function return values."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_returning_shorthands
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Shorthand Patterns</span>

This rule flags an arrow function that constructs the very type it declares as its return type. The declared type already names the class, so `.new(...)` or `.named(...)` carries the same information in fewer characters. The quick fix drops the prefix.

**See also:** [Dart language — dot shorthands](https://dart.dev/language/dot-shorthands)

## Don't

```dart
class Money {
  const Money(this.amount);
  const Money.zero() : amount = 0;

  final int amount;
}

Money parsePrice(String raw) => Money(int.parse(raw));         // LINT

Money emptyCart() => Money.zero();                             // LINT

Money priceOr(String? raw, bool free) =>
    free ? Money.zero() : Money(int.parse(raw!));              // LINT twice
```

## Do

```dart
Money parsePrice(String raw) => .new(int.parse(raw));

Money emptyCart() => .zero();

Money priceOr(String? raw, bool free) =>
    free ? .zero() : .new(int.parse(raw!));
```

Both branches of a conditional are checked independently, so a mixed expression
reports only the branches that construct the return type.

## A nullable return type still counts

`Money?` accepts a `Money`, so the shorthand is available there too:

```dart
// Don't
Money? tryParse(String raw) => Money(int.parse(raw));

// Do
Money? tryParse(String raw) => .new(int.parse(raw));
```

## Methods and factory constructors

The rule reads a method's declared return type the same way, and treats a
factory constructor's class as its return type:

```dart
// Don't
class Money {
  const Money(this.amount);
  const Money._(this.amount);

  factory Money.fromCents(int cents) => Money._(cents ~/ 100);   // LINT

  final int amount;

  Money doubled() => Money(amount * 2);                          // LINT
}

// Do
class Money {
  const Money(this.amount);
  const Money._(this.amount);

  factory Money.fromCents(int cents) => ._(cents ~/ 100);

  final int amount;

  Money doubled() => .new(amount * 2);
}
```

## Known limitations

**Only arrow bodies.** A block body is not reported, even when its single `return` constructs the declared type:

```dart
// Not reported
Money parsePrice(String raw) {
  return Money(int.parse(raw));
}
```

**A declared return type is required.** With no annotation, or with `dynamic` or `void`, there is no context type and the shorthand would not compile — nothing is reported.

**Only the outermost expression.** `Money('1').copy()` returns a `Money` but the expression is a method call on a constructor, so it is left alone.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_returning_shorthands: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_returning_shorthands: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_nested_shorthands`](/many_lints/docs/rules/shorthand-patterns/avoid-nested-shorthands/) — Avoid nesting a dot shorthand inside another dot shorthand invocation.
- [`prefer_shorthands_with_constructors`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-constructors/) — Use dot shorthand constructors for common Flutter classes.
- [`prefer_shorthands_with_enums`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-enums/) — Use dot shorthands instead of explicit enum prefixes.
- [`prefer_shorthands_with_static_fields`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-static-fields/) — Use dot shorthands instead of explicit class prefixes for static fields.
