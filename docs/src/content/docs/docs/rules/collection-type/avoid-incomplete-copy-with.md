---
title: avoid_incomplete_copy_with
description: "Ensure copyWith methods include all constructor parameters."
sidebar:
  label: avoid_incomplete_copy_with
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
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

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_incomplete_copy_with: false
```
