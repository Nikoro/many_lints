---
title: prefer_getter_over_method
description: "Make a no-argument value read a getter"
sidebar:
  label: prefer_getter_over_method
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags a no-argument method whose body only reads a value, where a getter reads as the property it is.

## Why use this rule

`order.getTotal()` and `order.total` return the same thing, but only the second reads as a property of the order. Effective Dart's rule is that a member doing no real work and taking no arguments should be a getter; the empty parentheses otherwise suggest something happens when you call it.

This rule is in the **`pedantic`** preset, because where the line falls between "a property" and "a call" is a genuine API-design judgement.

**See also:** [Effective Dart: prefer a getter](https://dart.dev/effective-dart/design#prefer-making-declarations-private)

## Don't

```dart
class Order {
  const Order(this.lineTotal, this.taxRate);

  final int lineTotal;
  final double taxRate;

  int tax() => (lineTotal * taxRate).round();

  bool isEmpty() => lineTotal == 0;
}
```

## Do

```dart
class Order {
  const Order(this.lineTotal, this.taxRate);

  final int lineTotal;
  final double taxRate;

  int get tax => (lineTotal * taxRate).round();

  bool get isEmpty => lineTotal == 0;
}
```

Call sites lose the parentheses: `order.tax`, `order.isEmpty`.

## Known limitations

Only an **expression body built from field reads and operators** is reported. Everything below keeps its parentheses:

**A body that calls anything.** `Clock.now()` answers differently on each call, and a getter promises a stable property. This includes constructing an object:

```dart
class Session {
  const Session(this.startedAt);

  final DateTime startedAt;

  // Not reported: the body calls something.
  Duration age() => DateTime.now().difference(startedAt);

  // Not reported: the body allocates.
  List<String> tags() => <String>['a', 'b'];
}
```

**A conventional name.** `toJson`, `toMap`, `toString`, `noSuchMethod`, `call`, `copyWith`, `toList` and `toSet` are shapes a reader expects invoked.

**A `Stream` or `Future` return type**, and any `async` or generator body. A stream is something you subscribe to, not a property you read, so `watchUser()` keeps its parentheses.

**A block body.** It may be doing the work the parentheses promise, so `int total() { return _amount; }` is left alone.

**A `void` method** (called for an effect), an **`@override`** (which must keep the supertype's shape), a **generic method** (a getter cannot take type arguments), an **operator**, and any method with a **missing return type annotation**.

Top-level functions are never reported — only methods on a class, mixin or extension.

## Enabling this rule

This rule is in the **`pedantic`** preset, so it is enabled by `preset: pedantic` or by name:

```yaml
# many_lints.yaml
rules:
  prefer_getter_over_method:
    enabled: true
```

## Turning this rule off

To disable this rule:

```yaml
# many_lints.yaml
rules:
  prefer_getter_over_method: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`match_getter_setter_field_names`](/many_lints/docs/rules/code-quality/match-getter-setter-field-names/) — Make a getter and setter pair use the same field.
- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
- [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/) — Detect and flag commented-out code.
- [`avoid_complex_conditions`](/many_lints/docs/rules/code-quality/avoid-complex-conditions/) — Keep boolean conditions within an operand budget.
