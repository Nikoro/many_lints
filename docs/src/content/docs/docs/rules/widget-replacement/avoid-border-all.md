---
title: avoid_border_all
description: "Use Border.fromBorderSide instead of Border.all for const support"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_border_all
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags usages of `Border.all()` which should be replaced with `Border.fromBorderSide(BorderSide(...))`. The `Border.all()` factory delegates to `Border.fromBorderSide()` internally, but it cannot be made `const` because it is a factory constructor.

## Why use this rule

`Border.all()` is a *factory*, and a factory can never be `const`. It forwards
straight to `Border.fromBorderSide(BorderSide(...))`, which can. Spelling out
the second form lets the whole `BoxDecoration` around it become constant, so it
is built once at compile time instead of on every `build`.

**See also:** [Border](https://api.flutter.dev/flutter/painting/Border-class.html) | [Dart lint: prefer_const_constructors](https://dart.dev/tools/linter-rules/prefer_const_constructors)

## Don't

```dart
// A bordered field, reallocated on every frame.
Container(
  decoration: BoxDecoration(
    border: Border.all(color: const Color(0xFF3355AA), width: 2), // LINT
  ),
  child: const Text('Hello'),
);
```

## Do

```dart
Container(
  decoration: const BoxDecoration(
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFF3355AA), width: 2),
    ),
  ),
  child: const Text('Hello'),
);
```

## Examples

### The default border

`Border.all()` with no arguments is a 1px black border. Its explicit form is
`BorderSide()`, whose defaults are the same:

```dart
// Don't
final border = Border.all();

// Do
const border = Border.fromBorderSide(BorderSide());
```

### Hoisting to a shared constant

Once const-capable, the border can live outside `build` and be shared by every
call site:

```dart
// Don't — a fresh Border on every call site, on every rebuild
BoxDecoration(border: Border.all(color: const Color(0xFFCCCCCC)));

// Do
const kFieldBorder = Border.fromBorderSide(
  BorderSide(color: Color(0xFFCCCCCC)),
);

const BoxDecoration(border: kFieldBorder);
```

### A non-constant argument is still reported

```dart
// Don't
final border = Border.all(color: theme.dividerColor);

// Do
final border = Border.fromBorderSide(BorderSide(color: theme.dividerColor));
```

`theme.dividerColor` is not a compile-time constant, so `const` is unavailable
here — but the explicit form is what the rule asks for, and it becomes const the
moment the colour does.

## Known limitations

**The fix does not add `const` for you.** It rewrites `Border.all(args)` into
`Border.fromBorderSide(BorderSide(args))` and stops. Adding the keyword is the
SDK's
[`prefer_const_constructors`](https://dart.dev/tools/linter-rules/prefer_const_constructors)
job — turn that on to collect the other half of the win.

**Only `Border.all` is matched,** because it is the only `Border` constructor
that is a factory. `Border.fromBorderSide`, `Border.symmetric` and the default
`Border(...)` are all already `const`, so there is nothing to report.

**`Border.all` on a subclass is not matched.** The check is for an expression
whose static type is exactly `Border`; a `Border` subclass of your own with its
own `all` factory is left alone.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_border_all: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_border_all: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_const_border_radius`](/many_lints/docs/rules/widget-replacement/prefer-const-border-radius/) — Use BorderRadius.all(Radius.circular()) for const support.
- [`avoid_expanded_as_spacer`](/many_lints/docs/rules/widget-replacement/avoid-expanded-as-spacer/) — Use Spacer instead of Expanded with an empty child.
- [`avoid_incorrect_image_opacity`](/many_lints/docs/rules/widget-replacement/avoid-incorrect-image-opacity/) — Use Image's opacity parameter instead of wrapping in Opacity.
- [`avoid_wrapping_in_padding`](/many_lints/docs/rules/widget-replacement/avoid-wrapping-in-padding/) — Avoid wrapping widgets that support padding in a Padding widget.
