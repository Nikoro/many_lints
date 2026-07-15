---
title: prefer_private_named_parameters
description: "Prefer private named parameters (Dart 3.12+) over initializer-list boilerplate."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_private_named_parameters
---

<span class="rule-badge rule-badge--version">v0.7.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

Warns when a constructor declares a public named parameter whose only purpose is to initialize a private field of the same name through the initializer list. Since Dart 3.12, a named initializing formal can be private directly (`this._name`), and callers still use the public name.

## Why use this rule

Before Dart 3.12, a named parameter could not start with an underscore, so initializing a private field from a named parameter required boilerplate: declare a public parameter, then assign it in the initializer list. Dart 3.12 removes that restriction — `Foo({required this._name})` is valid and is called as `Foo(name: ...)`. The shorter form eliminates a redundant local name, keeps the parameter and field in sync, and cannot drift (e.g. assigning the wrong parameter to the wrong field).

The rule only reports when the conversion is behavior-preserving: the parameter is used solely in that one initializer, its declared type matches the field type, and the library's language version is 3.12 or later.

**See also:** [Announcing Dart 3.12](https://dart.dev/blog/announcing-dart-3-12) | [Constructors: Initializing formal parameters](https://dart.dev/language/constructors#use-initializing-formal-parameters)

## Don't

```dart
class Bird {
  final String _petName;

  // LINT: petName exists only to initialize _petName
  Bird({required String petName}) : _petName = petName;
}
```

## Do

```dart
class Bird {
  final String _petName;

  // Callers still write Bird(petName: ...)
  Bird({required this._petName});
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_private_named_parameters: false
```
