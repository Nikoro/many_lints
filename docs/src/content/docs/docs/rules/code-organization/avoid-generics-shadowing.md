---
title: avoid_generics_shadowing
description: "Avoid generic type parameters that shadow top-level declarations."
sidebar:
  label: avoid_generics_shadowing
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Organization</span>

Flags generic type parameters that shadow a top-level type declaration (class, mixin, enum, typedef, or extension type) in the same file. When a type parameter has the same name as a real class, it becomes confusing whether a reference points to the generic or the concrete type.

## Why use this rule

Shadowing a top-level type with a generic parameter silently replaces the concrete type with an unbounded generic within that scope. This can lead to subtle bugs where code appears to reference a specific class but actually operates on an unrelated type parameter. Using conventional single-letter names like `T`, `R`, or `E` eliminates the ambiguity.

**See also:** [Dart language - Generics](https://dart.dev/language/generics)

## Don't

```dart
class MyModel {}
enum MyEnum { first, second }

// Generic type parameter shadows the top-level class MyModel
class Repository<MyModel> {
  MyModel get(int id) => throw '';
}

class SomeClass {
  // MyEnum shadows the top-level enum
  void method<MyEnum>(MyEnum p) {}
}

// Both type parameters shadow top-level types
class BadPair<MyModel, AnotherClass> {
  final MyModel first;
  final AnotherClass second;
  BadPair(this.first, this.second);
}
```

## Do

```dart
class MyModel {}
enum MyEnum { first, second }

// Use conventional single-letter type parameters
class GoodRepository<T> {
  T get(int id) => throw '';
}

// Descriptive names that don't shadow top-level types
class GoodPair<TFirst, TSecond> {
  final TFirst first;
  final TSecond second;
  GoodPair(this.first, this.second);
}

class Processor {
  void process<T>(T item) {}
  R transform<R>(Object input) => throw '';
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_generics_shadowing: false
```
