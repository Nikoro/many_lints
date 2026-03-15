---
title: avoid_collection_methods_with_unrelated_types
description: "Avoid calling collection methods with arguments whose types are unrelated to the collection's type parameter."
sidebar:
  label: avoid_collection_methods_with_unrelated_types
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Calling collection methods like `contains()`, `remove()`, or `containsKey()` with an argument whose type is unrelated to the collection's type parameter will always return `null`, `false`, or `-1`. This indicates a logical error since Dart's type system allows it due to these methods accepting `Object?`.

## Why use this rule

Methods like `List.contains()` and `Map.containsKey()` accept `Object?` for historical reasons, so the compiler won't catch type mismatches. Passing a `String` to `List<int>.contains()` compiles fine but always returns `false`, hiding a bug.

**See also:** [Dart generics](https://dart.dev/language/generics)

## Don't

```dart
void example() {
  final list = <int>[1, 2, 3];

  // String argument on int list
  list.contains('a');
  list.remove('a');

  final set = <int>{1, 2, 3};

  // String argument on int set
  set.contains('a');
  set.lookup('a');

  final map = <int, String>{};

  // String key on int-keyed map
  map.containsKey('a');

  // int value on String-valued map
  map.containsValue(42);

  // String key on int-keyed map
  final value = map['a'];
  map.remove('a');
}
```

## Do

```dart
void example() {
  final list = <int>[1, 2, 3];
  list.contains(1);
  list.remove(2);
  list.indexOf(3);

  final set = <int>{1, 2, 3};
  set.contains(1);

  final map = <int, String>{};
  map.containsKey(1);
  map.containsValue('hello');
  final value = map[1];
  map.remove(1);

  // Subtypes are fine
  final numList = <num>[1, 2, 3];
  numList.contains(42); // int is subtype of num

  // Dynamic is allowed (type not statically known)
  dynamic unknown = 42;
  list.contains(unknown);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_collection_methods_with_unrelated_types: false
```
