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

Flags classes that directly extend `Equatable` instead of using `EquatableMixin`. Extending `Equatable` consumes the single `extends` slot in Dart, preventing your class from inheriting from any other base class. Using the mixin keeps the `extends` slot free while providing identical functionality.

## Why use this rule

Dart only allows single inheritance. By using `with EquatableMixin` instead of `extends Equatable`, you preserve the ability to extend another meaningful base class while still getting value equality. This is especially important for domain models that might need to extend an existing hierarchy.

**See also:** [equatable package](https://pub.dev/packages/equatable)

## Don't

```dart
import 'package:equatable/equatable.dart';

class BadPerson extends Equatable {
  const BadPerson(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name, age];
}

abstract class BadBaseEntity extends Equatable {
  const BadBaseEntity();
}
```

## Do

```dart
import 'package:equatable/equatable.dart';

class GoodPerson with EquatableMixin {
  GoodPerson(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name, age];
}

// Can extend another class while using EquatableMixin
class Pet extends Animal with EquatableMixin {
  const Pet(super.species, this.name);
  final String name;

  @override
  List<Object?> get props => [species, name];
}

abstract class GoodBaseEntity with EquatableMixin {
  const GoodBaseEntity();
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_equatable_mixin: false
```
