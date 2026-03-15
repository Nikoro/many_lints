---
title: prefer_explicit_function_type
description: "Prefer explicit function type annotations over the bare 'Function' type."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_explicit_function_type
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Type Annotations</span>

Flags uses of the bare `Function` type that do not specify a return type or parameter list. Using the unparameterized `Function` type effectively makes the declaration dynamic and disables type checking on calls, which can hide bugs.

## Why use this rule

The bare `Function` type accepts any number and type of arguments and returns `dynamic`, bypassing Dart's type system entirely. Specifying the return type and parameter list catches mismatched signatures at compile time rather than at runtime.

**See also:** [Dart language - Function type](https://dart.dev/language/functions#the-function-type)

## Don't

```dart
class BadWidget {
  final Function onTap;
  final Function? onLongPress;

  const BadWidget(this.onTap, this.onLongPress);
}

void badFunction(Function callback) {}

Function badReturnType() => () {};

List<Function> callbacks = [];
```

## Do

```dart
class GoodWidget {
  final void Function() onTap;
  final void Function()? onLongPress;

  const GoodWidget(this.onTap, this.onLongPress);
}

void goodFunction(void Function() callback) {}

void Function() goodReturnType() => () {};

List<void Function()> callbacks = [];

// Function types with parameters and return types
final void Function(int value) onValueChanged = (_) {};
final int Function(String input) processInput = (_) => 0;
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_explicit_function_type: false
```
