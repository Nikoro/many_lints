---
title: list_all_equatable_fields
description: "Ensure all fields are listed in Equatable props."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: list_all_equatable_fields
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Classes that extend `Equatable` or use `EquatableMixin` must include all declared instance fields in the `props` getter. Missing fields means two instances with different values for those fields will be considered equal, leading to hard-to-find bugs.

## Why use this rule

Forgetting to add a field to `props` silently breaks equality comparisons. Two objects that differ only in the missing field will appear equal, which can cause incorrect behavior in collections, state management, and testing.

**See also:** [equatable package](https://pub.dev/packages/equatable)

## Don't

```dart
import 'package:equatable/equatable.dart';

// Missing 'age' from props
class BadPerson extends Equatable {
  const BadPerson(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name];
}

// Missing all fields from props
class BadEmpty extends Equatable {
  const BadEmpty(this.x, this.y);
  final double x;
  final double y;

  @override
  List<Object?> get props => [];
}

// Using EquatableMixin with missing field
class BadMixinPerson with EquatableMixin {
  BadMixinPerson(this.name, this.email);
  final String name;
  final String email;

  @override
  List<Object?> get props => [name];
}
```

## Do

```dart
import 'package:equatable/equatable.dart';

// All fields are listed in props
class GoodPerson extends Equatable {
  const GoodPerson(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name, age];
}

// All fields listed with EquatableMixin
class GoodMixinPerson with EquatableMixin {
  GoodMixinPerson(this.name, this.email);
  final String name;
  final String email;

  @override
  List<Object?> get props => [name, email];
}

// Static fields are correctly excluded
class PersonWithStatic extends Equatable {
  const PersonWithStatic(this.name);
  final String name;
  static const maxNameLength = 100;

  @override
  List<Object?> get props => [name];
}

// No fields means empty props is fine
class EmptyEquatable extends Equatable {
  const EmptyEquatable();

  @override
  List<Object?> get props => [];
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      list_all_equatable_fields: false
```
