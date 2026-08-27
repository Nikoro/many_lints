---
title: prefer_const_border_radius
description: "Use BorderRadius.all(Radius.circular()) for const support"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_const_border_radius
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags usages of `BorderRadius.circular()` which should be replaced with `BorderRadius.all(Radius.circular(...))`. The `BorderRadius.circular()` factory delegates to `BorderRadius.all(Radius.circular())` internally, but it cannot be made `const` because it is a factory constructor.

## Why use this rule

`BorderRadius.circular(8)` is a factory, and a factory can never be `const`. It
forwards straight to `BorderRadius.all(Radius.circular(8))`, which can. Writing
the second form lets the whole surrounding expression be constant, so it is
allocated once at compile time instead of on every `build`.

**See also:** [BorderRadius](https://api.flutter.dev/flutter/painting/BorderRadius-class.html) | [Dart lint: prefer_const_constructors](https://dart.dev/tools/linter-rules/prefer_const_constructors)

## Don't

```dart
// A rounded card decoration rebuilt on every frame.
Container(
  decoration: BoxDecoration(
    color: const Color(0xFFEEEEEE),
    borderRadius: BorderRadius.circular(8), // LINT
  ),
  child: const Text('Hello'),
);
```

## Do

```dart
Container(
  decoration: const BoxDecoration(
    color: Color(0xFFEEEEEE),
    borderRadius: BorderRadius.all(Radius.circular(8)),
  ),
  child: const Text('Hello'),
);
```

## Examples

### A shared radius constant

Once the expression is const-capable, it can be hoisted to a top-level constant
and reused:

```dart
// Don't — a new object per call site, per build
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: const Text('Clipped'),
);

// Do
const kCardRadius = BorderRadius.all(Radius.circular(12));

ClipRRect(borderRadius: kCardRadius, child: const Text('Clipped'));
```

### Any argument shape is reported

The radius does not have to be a literal — the rule reports the factory call
itself:

```dart
// Don't
final radius = BorderRadius.circular(spacing * 2);

// Do
final radius = BorderRadius.all(Radius.circular(spacing * 2));
```

Here the value is not constant, so `const` is not available — but the explicit
form is still what the rule asks for, and it becomes const the moment `spacing`
does.

## Known limitations

**The fix does not add `const` for you.** It rewrites
`BorderRadius.circular(r)` into `BorderRadius.all(Radius.circular(r))` and
stops there. Adding the keyword is the SDK's
[`prefer_const_constructors`](https://dart.dev/tools/linter-rules/prefer_const_constructors)
job — turn that on to get the second half of the win.

**Only `BorderRadius.circular` is matched.** `BorderRadius.horizontal`,
`BorderRadius.vertical` and `BorderRadius.only` are factories too, but they take
`Radius` arguments rather than doubles, so there is no mechanical rewrite to
offer.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_const_border_radius: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_const_border_radius: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_border_all`](/many_lints/docs/rules/widget-replacement/avoid-border-all/) — Use Border.fromBorderSide instead of Border.all for const support.
- [`avoid_expanded_as_spacer`](/many_lints/docs/rules/widget-replacement/avoid-expanded-as-spacer/) — Use Spacer instead of Expanded with an empty child.
- [`avoid_incorrect_image_opacity`](/many_lints/docs/rules/widget-replacement/avoid-incorrect-image-opacity/) — Use Image's opacity parameter instead of wrapping in Opacity.
- [`avoid_wrapping_in_padding`](/many_lints/docs/rules/widget-replacement/avoid-wrapping-in-padding/) — Avoid wrapping widgets that support padding in a Padding widget.
