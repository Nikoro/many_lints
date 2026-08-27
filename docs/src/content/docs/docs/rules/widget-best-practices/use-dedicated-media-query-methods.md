---
title: use_dedicated_media_query_methods
description: "Use MediaQuery.sizeOf(context) instead of MediaQuery.of(context).size"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_dedicated_media_query_methods
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags `MediaQuery.of(context).<property>` where a dedicated `<property>Of(context)` accessor exists.

`MediaQuery.of(context)` subscribes to the whole `MediaQueryData`, so the widget rebuilds when *anything* changes: orientation, padding, text scale, view insets, the on-screen keyboard appearing. `MediaQuery.sizeOf(context)` subscribes to one aspect, and rebuilds only when that aspect changes. In a frequently-rebuilt subtree that is a real win. The quick fix rewrites the call.

This rule is in the **`recommended`** preset, so it is on with `preset: recommended` and every preset above it. No configuration.

**See also:** [MediaQuery](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)

## Don't

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Subscribes to ALL MediaQuery changes — a keyboard opening rebuilds this
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    return SizedBox(width: size.width, height: size.height - padding.top);
  }
}
```

## Do

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds only when the size or the padding changes
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return SizedBox(width: size.width, height: size.height - padding.top);
  }
}
```

### The naming rule

The accessor is the property name with `Of` appended, so the rewrite is mechanical:

| Instead of | Use |
|-----------|-----|
| `MediaQuery.of(context).size` | `MediaQuery.sizeOf(context)` |
| `MediaQuery.of(context).orientation` | `MediaQuery.orientationOf(context)` |
| `MediaQuery.of(context).viewInsets` | `MediaQuery.viewInsetsOf(context)` |
| `MediaQuery.of(context).textScaler` | `MediaQuery.textScalerOf(context)` |
| `MediaQuery.of(context).platformBrightness` | `MediaQuery.platformBrightnessOf(context)` |
| `MediaQuery.of(context).devicePixelRatio` | `MediaQuery.devicePixelRatioOf(context)` |

### maybeOf keeps its null

`MediaQuery.maybeOf` has a `maybe<Property>Of` counterpart, and the fix inserts the `?` where the chain needs it:

```dart
// Don't
final width = MediaQuery.maybeOf(context)?.size.width;

// Do
final width = MediaQuery.maybeSizeOf(context)?.width;
```

## Known limitations

Only a **direct** property access on the call is reported — `MediaQuery.of(context).size`. Binding the data first hides it, even though the subscription is exactly as wide:

```dart
// Not reported, but subscribes to everything all the same
final media = MediaQuery.of(context);
final size = media.size;
```

The receiver is matched by the literal name `MediaQuery`, so an aliased import (`as flutter`) is not recognised.

Only properties with a real dedicated accessor are reported; anything else is left alone.

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  use_dedicated_media_query_methods: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/) — Don't create a GlobalKey inside build.
- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
- [`avoid_deep_widget_nesting`](/many_lints/docs/rules/widget-best-practices/avoid-deep-widget-nesting/) — Keep a widget tree within a nesting budget.
- [`avoid_flexible_outside_flex`](/many_lints/docs/rules/widget-best-practices/avoid-flexible-outside-flex/) — Only use Flexible and Expanded as direct children of Row, Column, or Flex.
