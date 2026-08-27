---
title: prefer_equatable_mixin
description: "Prefer using EquatableMixin instead of extending Equatable."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_equatable_mixin
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Type Annotations</span>

Flags a class that extends `Equatable` from `package:equatable` instead of mixing in `EquatableMixin`. Both give the same value equality; only one leaves the `extends` slot free.

## Don't

Dart allows a single superclass. Spending it on `Equatable` means the day this
model needs a real base class, the equality has to be reworked first:

```dart
import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  const CartItem(this.sku, this.quantity);

  final String sku;
  final int quantity;

  @override
  List<Object?> get props => [sku, quantity];
}
```

## Do

```dart
import 'package:equatable/equatable.dart';

class CartItem with EquatableMixin {
  CartItem(this.sku, this.quantity);

  final String sku;
  final int quantity;

  @override
  List<Object?> get props => [sku, quantity];
}
```

### The point: `extends` stays available

With the mixin, the same model can join a hierarchy without giving up equality:

```dart
import 'package:equatable/equatable.dart';

abstract class DomainEntity {
  const DomainEntity(this.id);

  final String id;
}

class CartItem extends DomainEntity with EquatableMixin {
  CartItem(super.id, this.sku, this.quantity);

  final String sku;
  final int quantity;

  @override
  List<Object?> get props => [id, sku, quantity];
}
```

### Abstract bases too

An abstract class that extends `Equatable` passes the same constraint on to
every subclass:

```dart
import 'package:equatable/equatable.dart';

// Don't — every subclass now has its `extends` slot spent.
abstract class BaseEntity extends Equatable {
  const BaseEntity();
}

// Do
abstract class BaseEntity with EquatableMixin {
  const BaseEntity();
}
```

### Not reported

Only `extends Equatable` is reported. A class that already uses the mixin, and
a class extending something else entirely, are left alone.

**See also:** [equatable package](https://pub.dev/packages/equatable)

## Configuration

This rule is in **no preset**, so it is off unless you enable it by name:

```yaml
# many_lints.yaml
rules:
  prefer_equatable_mixin: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_equatable_mixin: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`list_all_equatable_fields`](/many_lints/docs/rules/collection-type/list-all-equatable-fields/) — Ensure all fields are listed in Equatable props.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
- [`prefer_overriding_parent_equality`](/many_lints/docs/rules/collection-type/prefer-overriding-parent-equality/) — Override == and hashCode when the parent class overrides them.
- [`prefer_async_callback`](/many_lints/docs/rules/type-annotations/prefer-async-callback/) — Use 'AsyncCallback' instead of 'Future&lt;void&gt; Function()'.
