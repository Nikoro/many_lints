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

Flags the bare `Function` type from `dart:core` — the one written with no return type and no parameter list.

`Function` accepts any number of arguments of any type and returns `dynamic`, so a call through it is unchecked. The compiler will not tell you that the callback you passed takes two arguments and you supplied one; you find out at runtime.

## Don't

A callback field typed `Function` accepts anything, so the wrong callback
compiles and the wrong call compiles with it:

```dart
class ConfirmDialog {
  const ConfirmDialog({required this.onConfirm});

  final Function onConfirm;
}

void show(ConfirmDialog dialog) {
  // Compiles. Blows up at runtime if `onConfirm` takes no argument,
  // or takes two, or takes a String.
  dialog.onConfirm(42);
}
```

The same hole in a parameter, a return type and a collection:

```dart
void onEachRow(Function visit) {}

Function rowVisitor() => (int index) {};

final List<Function> validators = [];
```

## Do

Write the signature out. Every one of the mistakes above is now a compile
error:

```dart
class ConfirmDialog {
  const ConfirmDialog({required this.onConfirm});

  final void Function(bool confirmed) onConfirm;
}

void show(ConfirmDialog dialog) {
  dialog.onConfirm(true);
}

void onEachRow(void Function(int index) visit) {}

void Function(int index) rowVisitor() => (int index) {};

final List<bool Function(String value)> validators = [];
```

### What counts as explicit

Anything that names the shape is fine — an inline function type, or a typedef:

```dart
typedef Validator = bool Function(String value);

final Validator notEmpty = (value) => value.isNotEmpty;
final int Function(String input) parse = int.parse;
final void Function() dismiss = () {};
```

### Not reported

The rule matches `dart:core`'s `Function` specifically, so a class of your own
named `Function` is never reported.

**See also:** [Dart language - Function type](https://dart.dev/language/functions#the-function-type)

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`prefer_explicit_function_type: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_explicit_function_type: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_explicit_parameter_names`](/many_lints/docs/rules/type-annotations/prefer-explicit-parameter-names/) — Name the parameters of a function type.
- [`prefer_typedefs_for_callbacks`](/many_lints/docs/rules/type-annotations/prefer-typedefs-for-callbacks/) — Name a multi-parameter function type with a typedef.
- [`prefer_void_callback`](/many_lints/docs/rules/type-annotations/prefer-void-callback/) — Use 'VoidCallback' instead of 'void Function()'.
- [`prefer_explicit_type_arguments`](/many_lints/docs/rules/type-annotations/prefer-explicit-type-arguments/) — Pin the type arguments of the APIs where inference surprises.
