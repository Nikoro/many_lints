---
title: prefer_primary_constructors
description: "Move a class or enum constructor into the type header as a primary constructor (Dart 3.13+), without touching types that declare none."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_primary_constructors
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

Warns when a class or enum declares a generative constructor that can move into the type header as a Dart 3.13 primary constructor. The field list, the parameter list and the assignments stop being three copies of the same information.

A type that declares no constructor is never reported. That is the difference from the SDK's `use_primary_constructors`, which also wants `enum Sport() {` and `abstract interface class Gateway() {`.

## Why use this rule

A class written the old way names each field three times: in the field declaration, in the constructor parameter list, and in the assignment. A primary constructor declares all three at once, so adding a field and forgetting the constructor stops being possible.

**See also:** [Primary constructors](https://dart.dev/language/primary-constructors) | [Feature specification](https://github.com/dart-lang/language/blob/main/accepted/3.13/primary-constructors/feature-specification.md)

## Don't

```dart
// LINT: the fields, the parameters and the assignments are three copies
// of the same list.
class CartLine {
  final String sku;
  final int quantity;
  CartLine(this.sku, this.quantity);

  int get total => quantity * 2;
}
```

```dart
// LINT: an enum constructor moves too.
enum Currency {
  pln('zł'),
  eur('€');

  const Currency(this.symbol);

  final String symbol;
}
```

## Do

```dart
class CartLine(final String sku, final int quantity) {
  int get total => quantity * 2;
}
```

```dart
enum Currency(final String symbol) {
  pln('zł'),
  eur('€');
}
```

### Initializer lists and bodies move into a `this` block

```dart
class Account(final String id, int balance) {
  final int cents;

  this : cents = balance * 100, assert(balance >= 0);
}
```

### Types without a constructor stay as they are

```dart
enum Sport { squash, padel }

abstract interface class Gateway {
  Future<void> send();
}
```

## What is reported

A class or enum with exactly one generative constructor that does not redirect. Any other constructor must be a factory or redirect with `: this(...)`, since that is all a primary constructor allows beside it. The class may have methods, other fields, a superclass, `super.x` parameters, plain parameters, an initializer list and a body.

Not reported, because the rewrite has no faithful form:

- a second generative constructor that does not redirect,
- an annotation on the constructor,
- a `this.x` whose field is `late`, `covariant`, `external` or `abstract`,
- `int this.x` (an explicit type may be narrower than the field's) and `this.cb(int v)`,
- `final int a, b;` when the constructor declares only some of them,
- a `mixin class` whose constructor is not trivial.

**The library must be on language version 3.13 or later.** A file pinned to an older version is skipped.

### Quick fix

The fix rewrites the header and the body in one edit:

- The parameter list is the constructor's own, with each `this.x` replaced by `final int x` (or `var int x` for a mutable field). Order, `required`, defaults and brace groups stay as they were.
- `const` moves onto the header (`class const Point(...)`). An enum's constructor is implicitly const, so the fix leaves it out.
- An initializer list and a non-empty body go into a `this` block. An initializer list is never turned into a field initializer.
- Comments are never deleted. A field's comments, doc comment and annotations move with it into the header. The constructor's comments move there too, unless a `this` block remains for them to stay above.
- A class body left empty becomes `;`.

The quick fix works in the IDE. `dart fix --apply` in Dart 3.13 does not apply fixes from analyzer plugins.

### Interaction with SDK lints

Turn off the SDK's `use_primary_constructors` when you use this rule. It reports the same constructors, plus every type that has none.

`use_declaring_parameters`, `unnecessary_primary_constructor_body` and `empty_container_bodies` only look at code that already migrated, so they combine well with this rule. `unnecessary_type_name_in_constructor` suggests `new(this.x)` for the same constructor. Either fix leaves code this rule still converts.

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
