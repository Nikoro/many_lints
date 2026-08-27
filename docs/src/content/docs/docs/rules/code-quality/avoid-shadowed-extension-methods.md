---
title: avoid_shadowed_extension_methods
description: "An extension member the extended type already has"
sidebar:
  label: avoid_shadowed_extension_methods
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags an extension member whose name already exists on the type being extended. Instance members always win over extension members, so the extension one can never be called.

The result is code that reads as though the extension applies and behaves as though it does not. Nothing errors, so the discrepancy is usually found by debugging the wrong thing.

This rule is in the **`core`** preset and takes no configuration.

## Don't

```dart
extension StringShouting on String {
  // Never called — String.toUpperCase always wins at every call site.
  String toUpperCase() => '$this!';
}

String announce(String name) => name.toUpperCase();   // 'ADA', not 'Ada!'
```

## Do

Give the extension member a name the type does not already use:

```dart
extension StringShouting on String {
  String shout() => '$this!';
}

String announce(String name) => name.shout();         // 'Ada!'
```

## More examples

### Shadowing a getter you added to your own class

The type does not have to be from the SDK. This bites hardest on your own
classes, where the instance member was added *after* the extension:

```dart
class Cart {
  const Cart(this.lines);

  final List<int> lines;

  int get total => lines.fold(0, (sum, line) => sum + line);
}

extension CartTotals on Cart {
  // Reported — Cart.total already exists, so this body never runs.
  int get total => 0;
}
```

```dart
extension CartTotals on Cart {
  int get totalWithTax => (total * 1.23).round();
}
```

### Inherited members shadow too

The check walks the extended type's supertypes, so a member inherited from a
base class shadows an extension just as an own member does:

```dart
class Entity {
  const Entity(this.id);

  final String id;

  String describe() => 'Entity($id)';
}

class Booking extends Entity {
  const Booking(super.id);
}

extension BookingDisplay on Booking {
  // Reported — Booking inherits describe() from Entity.
  String describe() => 'Booking $id';
}
```

## Known limitations

Members inherited from `Object` are excluded. The compiler already rejects those outright (`extension_declares_member_of_object`), so there is nothing left for this rule to say, and the exclusion also keeps it from flagging every supertype's inherited `toString`.

Static extension members are skipped, since they are accessed through the extension name and cannot be shadowed:

```dart
extension DurationParsing on Duration {
  // Not reported — called as DurationParsing.parse(...).
  static Duration parse(String source) => Duration.zero;
}
```

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_shadowed_extension_methods: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_too_many_methods`](/many_lints/docs/rules/code-quality/avoid-too-many-methods/) — Keep a class within a method budget.
- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
- [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/) — Detect and flag commented-out code.
- [`avoid_complex_conditions`](/many_lints/docs/rules/code-quality/avoid-complex-conditions/) — Keep boolean conditions within an operand budget.
