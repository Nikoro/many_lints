---
title: avoid_incomplete_copy_with
description: "Ensure copyWith methods include all constructor parameters."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_incomplete_copy_with
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

A `copyWith` method that does not include all parameters from the class's default constructor is incomplete. Callers cannot override every field, which defeats the purpose of having a `copyWith` method in the first place.

## Why use this rule

An incomplete `copyWith` is a common source of subtle bugs. When a new field is added to a class but not to `copyWith`, callers silently lose the ability to override that field. This rule ensures your `copyWith` stays in sync with the constructor.

**See also:** [Effective Dart: Design](https://dart.dev/effective-dart/design)

## Don't

```dart
// copyWith is missing the 'surname' parameter
class IncompletePerson {
  const IncompletePerson({required this.name, required this.surname});

  final String name;
  final String surname;

  IncompletePerson copyWith({String? name}) {
    return IncompletePerson(name: name ?? this.name, surname: surname);
  }
}

// copyWith is missing both 'port' and 'path'
class IncompleteConfig {
  const IncompleteConfig({
    required this.host,
    required this.port,
    required this.path,
  });

  final String host;
  final int port;
  final String path;

  IncompleteConfig copyWith({String? host}) {
    return IncompleteConfig(host: host ?? this.host, port: port, path: path);
  }
}
```

## Do

```dart
// copyWith includes all constructor parameters
class CompletePerson {
  const CompletePerson({required this.name, required this.surname});

  final String name;
  final String surname;

  CompletePerson copyWith({String? name, String? surname}) {
    return CompletePerson(
      name: name ?? this.name,
      surname: surname ?? this.surname,
    );
  }
}

// No copyWith method — no warning
class NoCopyWith {
  const NoCopyWith({required this.value});

  final int value;
}
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_incomplete_copy_with: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_incomplete_copy_with: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
- [`avoid_collection_methods_with_unrelated_types`](/many_lints/docs/rules/collection-type/avoid-collection-methods-with-unrelated-types/) — Avoid calling collection methods with arguments whose types are unrelated to the collection's type parameter.
- [`avoid_duplicate_collection_elements`](/many_lints/docs/rules/collection-type/avoid-duplicate-collection-elements/) — Don't repeat the same element in a collection literal.
