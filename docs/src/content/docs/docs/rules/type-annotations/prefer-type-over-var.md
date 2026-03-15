---
title: prefer_type_over_var
description: "Prefer an explicit type annotation over 'var'."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_type_over_var
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Type Annotations</span>

Flags variables declared with the `var` keyword instead of an explicit type annotation. Using `var` can make it harder to understand the type of a variable, especially when the initializer is complex or the nullability is not obvious. This rule does not flag `final` or `const` declarations.

## Why use this rule

Explicit type annotations improve code readability and make the type system work for you. When a variable is declared with `var`, readers must mentally resolve the initializer to understand the type, which slows down code review and increases the chance of subtle bugs around nullability or unexpected inference.

**See also:** [Effective Dart - Type annotations](https://dart.dev/effective-dart/design#types)

## Don't

```dart
var variable = nullableMethod();
var anotherVar = 'string';
var number = 42;
var list = [1, 2, 3];

for (var i = 0; i < 10; i++) {
  print(i);
}

var topLevelVariable = nullableMethod();
```

## Do

```dart
String? variable = nullableMethod();
String anotherVar = 'string';
int number = 42;
List<int> list = [1, 2, 3];

for (int i = 0; i < 10; i++) {
  print(i);
}

String? topLevelVariable = nullableMethod();

// final and const are allowed:
final inferred = nullableMethod();
const text = 'hello';
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_type_over_var: false
```
