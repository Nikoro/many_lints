---
title: avoid_unnecessary_gesture_detector
description: "Remove GestureDetector widgets that have no event handlers"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_gesture_detector
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a `GestureDetector` with no argument whose name starts with `on`.

A handler-less `GestureDetector` still takes part in hit testing, so it can quietly swallow touches meant for something underneath — especially with `behavior: HitTestBehavior.opaque`. Either the handler was deleted and the wrapper left behind, or the handler was never wired up and the tap has been dead since it shipped.

This rule is in the **`recommended`** preset, so it is on with `preset: recommended` and every preset above it. No configuration.

**See also:** [GestureDetector](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)

## Don't

The usual origin: the callback moved somewhere else and the wrapper stayed:

```dart
class ProductTile extends StatelessWidget {
  const ProductTile({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: const Text('Product'),
    );
  }
}
```

## Do

Either wire the handler back up:

```dart
class ProductTile extends StatelessWidget {
  const ProductTile({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: const Text('Product'),
    );
  }
}
```

Or drop the wrapper — the quick fix does this, replacing the `GestureDetector` with its `child`:

```dart
@override
Widget build(BuildContext context) => const Text('Product');
```

### Non-handler arguments do not count

`behavior`, `excludeFromSemantics`, `dragStartBehavior` and friends configure the detector; they do not give it anything to do. Only an `on*` argument counts:

```dart
// Still reported — no on* argument
GestureDetector(
  behavior: HitTestBehavior.translucent,
  excludeFromSemantics: true,
  child: const Text('Nothing happens'),
);
```

### Prefer InkWell when the tap is a Material one

If you are adding a handler back to get a tap, `InkWell` gives you the ripple as well:

```dart
InkWell(
  onTap: onOpen,
  child: const Text('Product'),
);
```

## Known limitations

Any argument whose name starts with `on` satisfies the rule, so `onSomethingElse: null` — an explicitly null handler — keeps it quiet. The rule reads the argument name, not the value.

`RawGestureDetector` and `Listener` are not checked.

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_gesture_detector: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/) — Don't create a GlobalKey inside build.
- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
- [`avoid_deep_widget_nesting`](/many_lints/docs/rules/widget-best-practices/avoid-deep-widget-nesting/) — Keep a widget tree within a nesting budget.
- [`avoid_flexible_outside_flex`](/many_lints/docs/rules/widget-best-practices/avoid-flexible-outside-flex/) — Only use Flexible and Expanded as direct children of Row, Column, or Flex.
