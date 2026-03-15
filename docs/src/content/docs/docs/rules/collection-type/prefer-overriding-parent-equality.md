---
title: prefer_overriding_parent_equality
description: "Override == and hashCode when the parent class overrides them."
sidebar:
  label: prefer_overriding_parent_equality
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

When a parent class overrides `==` and `hashCode`, child classes that add new fields should also override both operators. Otherwise, the inherited equality ignores the child's fields, meaning two child instances with different field values may be considered equal.

## Why use this rule

Inheriting a parent's `==` without overriding it in the child means the child's own fields are excluded from equality checks. This causes silent bugs in collections, state comparison, and testing where logically different objects appear identical.

**See also:** [Dart operator == and hashCode](https://dart.dev/guides/language/effective-dart/design#equality)

## Don't

```dart
class Parent {
  final int id;
  Parent(this.id);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Parent && id == other.id;
}

// Missing both == and hashCode overrides
class Child extends Parent {
  final String name;
  Child(this.name, int id) : super(id);
}

// Missing hashCode override
class ChildMissingHashCode extends Parent {
  final String name;
  ChildMissingHashCode(this.name, int id) : super(id);

  @override
  bool operator ==(Object other) =>
      other is ChildMissingHashCode && name == other.name && id == other.id;
}

// Missing == override
class ChildMissingEquals extends Parent {
  final String name;
  ChildMissingEquals(this.name, int id) : super(id);

  @override
  int get hashCode => Object.hash(id, name);
}
```

## Do

```dart
// Child overrides both == and hashCode
class GoodChild extends Parent {
  final String name;
  GoodChild(this.name, int id) : super(id);

  @override
  int get hashCode => Object.hash(id, name);

  @override
  bool operator ==(Object other) =>
      other is GoodChild && id == other.id && name == other.name;
}

// Abstract class is not flagged
abstract class AbstractChild extends Parent {
  final String label;
  AbstractChild(this.label, int id) : super(id);
}

// Parent does not override equality — no warning
class SimpleParent {
  final int x;
  SimpleParent(this.x);
}

class SimpleChild extends SimpleParent {
  final int y;
  SimpleChild(this.y, int x) : super(x);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_overriding_parent_equality: false
```
