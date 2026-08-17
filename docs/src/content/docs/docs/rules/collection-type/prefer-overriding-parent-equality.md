---
title: prefer_overriding_parent_equality
description: "Override == and hashCode when the parent class overrides them."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_overriding_parent_equality
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

When a parent class overrides `==` and `hashCode`, child classes that add new fields should also override both operators. Otherwise, the inherited equality ignores the child's fields, meaning two child instances with different field values may be considered equal.

## Why use this rule

Inheriting a parent's `==` without overriding it in the child means the child's own fields are excluded from equality checks. This causes silent bugs in collections, state comparison, and testing where logically different objects appear identical.

**See also:** [Dart operator == and hashCode](https://dart.dev/effective-dart/design#equality) | [Dart lint: hash_and_equals](https://dart.dev/tools/linter-rules/hash_and_equals)

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

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_overriding_parent_equality: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_overriding_parent_equality: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
- [`list_all_equatable_fields`](/many_lints/docs/rules/collection-type/list-all-equatable-fields/) — Ensure all fields are listed in Equatable props.
- [`prefer_equatable_mixin`](/many_lints/docs/rules/type-annotations/prefer-equatable-mixin/) — Prefer using EquatableMixin instead of extending Equatable.
- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
