---
title: avoid_flexible_outside_flex
description: "Only use Flexible and Expanded as direct children of Row, Column, or Flex"
sidebar:
  label: avoid_flexible_outside_flex
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a `Flexible` or `Expanded` that is not a direct child of a `Row`, `Column` or `Flex`.

Both widgets work by handing a flex factor to the parent's layout protocol. A non-flex parent — `Container`, `Padding`, `Center`, `SizedBox` — ignores it. Nothing throws at build time; the widget simply has no effect, which is why this is worth catching at lint time rather than by staring at the tree.

This rule is in the **`core`** preset, so it is on with `preset: core` and every preset above it. No configuration.

**See also:** [Flexible](https://api.flutter.dev/flutter/widgets/Flexible-class.html) | [Row](https://api.flutter.dev/flutter/widgets/Row-class.html)

## Don't

The usual way in is wrapping for padding *after* the layout already worked:

```dart
Column(
  children: [
    // Padding is not a Flex, so Expanded does nothing here
    Padding(
      padding: const EdgeInsets.all(8),
      child: Expanded(child: Text('Body')),
    ),
  ],
)
```

## Do

Keep `Expanded` next to the `Column` and move the wrapper inside it:

```dart
Column(
  children: [
    Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Body'),
      ),
    ),
  ],
)
```

### A nested Row needs its own Expanded

Nesting a flex inside a flex is fine — each `Expanded` just has to sit directly in one of them:

```dart
// Don't — Center swallows the flex factor
final bad = Row(
  children: [
    Center(child: Flexible(child: Text('Title'))),
  ],
);

// Do
final good = Row(
  children: [
    Flexible(child: Center(child: Text('Title'))),
  ],
);
```

### Nothing at all above it

A `Flexible` returned bare from a helper or built outside any flex parent is reported too — there is no layout to be flexible in:

```dart
// Don't
Widget spacerBar() => Expanded(child: Container());

// Do — return the child, and let the caller wrap it
Widget spacerBar() => Container();
```

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  avoid_flexible_outside_flex: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_single_child_in_multi_child_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-single-child-in-multi-child-widgets/) — Don't use Column, Row, or other multi-child widgets with only one child.
- [`prefer_for_loop_in_children`](/many_lints/docs/rules/code-organization/prefer-for-loop-in-children/) — Prefer collection-for syntax over functional list building in widget children.
- [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/) — Don't create a GlobalKey inside build.
- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
