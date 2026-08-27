---
title: avoid_wrapping_in_padding
description: "Avoid wrapping widgets that support padding in a Padding widget"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_wrapping_in_padding
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags a `Padding` whose child already takes a `padding` argument of its own —
`Container`, `ListView`, `GridView`, `SingleChildScrollView`,
`ReorderableListView`, `Chip`, and any of your own widgets that expose one. The
wrapper is a whole extra render object doing what the child would have done for
free.

The check is structural, not a fixed list: the rule looks at the child's
constructors and reports if any of them declares a named `padding` parameter.

## Why use this rule

Each `Padding` in the tree is a `RenderPadding` to lay out and paint. When the
child already accepts `padding:`, moving the value inward removes a level of
nesting and a render object, and puts the inset next to the widget it belongs
to. The quick fix does the move, carrying the `key` across if the `Padding` had
one.

**See also:** [Padding](https://api.flutter.dev/flutter/widgets/Padding-class.html) | [ScrollView.padding](https://api.flutter.dev/flutter/widgets/ScrollView/padding.html)

## Don't

```dart
// ListView takes its own padding. Wrapping it insets the whole viewport, so
// the scrollbar and the overscroll glow move inward with the content.
Padding(
  padding: EdgeInsets.all(16),
  child: ListView(children: items),
);
```

## Do

```dart
// The inset now applies to the content; the viewport still fills the space.
ListView(padding: EdgeInsets.all(16), children: items);
```

## Examples

### Your own widget counts too

Nothing here is hard-coded to Flutter's widgets. Give a widget a `padding`
parameter and the rule starts reporting `Padding` around it:

```dart
class Panel extends StatelessWidget {
  const Panel({super.key, this.padding, required this.child});

  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFEEEEEE),
    padding: padding,
    child: child,
  );
}
```

```dart
// Don't — Panel declares `padding`, so the wrapper is redundant
Padding(padding: const EdgeInsets.all(8), child: Panel(child: body));

// Do
Panel(padding: const EdgeInsets.all(8), child: body);
```

Note that a `padding` parameter your widget then ignores will still make the
rule report — it reads the constructor signature, not what `build` does with the
value.

### Wrapping a Container

:::caution[The obvious rewrite trips a sibling rule]
`Padding(padding: p, child: Container(child: x))` is reported here, and the
mechanical fix — `Container(padding: p, child: x)` — is then reported by
[`prefer_padding_over_container`](/many_lints/docs/rules/widget-replacement/prefer-padding-over-container/),
which wants a bare `Container` carrying only `padding` turned back into a
`Padding`. Both ship in `opinionated`.

For a `Container` with nothing else set, the answer is neither: **drop the
`Container`.**

```dart
// Don't
Padding(padding: EdgeInsets.all(16), child: Container(child: Text('Hello')));

// Do — the Container was doing nothing
Padding(padding: EdgeInsets.all(16), child: Text('Hello'));
```

The two rules only collide on a `Container` that is otherwise empty. Once it is
carrying a `color` or a `decoration`, `prefer_padding_over_container` is silent
and moving the padding in is the right move:

```dart
// Don't
Padding(
  padding: EdgeInsets.all(16),
  child: Container(
    color: const Color(0xFFEEEEEE),
    child: const Text('Hello'),
  ),
);

// Do — reported by nothing
Container(
  color: const Color(0xFFEEEEEE),
  padding: EdgeInsets.all(16),
  child: const Text('Hello'),
);
```
:::

## Known limitations

**A child that already sets `padding` is left alone.** Merging two insets is a
decision, not a rewrite:

```dart
// Not reported
Padding(
  padding: EdgeInsets.all(8),
  child: Container(padding: EdgeInsets.all(4), child: Text('Hello')),
);
```

**A `Padding` with no child is never reported** — there is nothing to move the
value into.

**Only the immediate child is examined.** `Padding > Center > ListView` is not
reported, even though the `ListView` could still take the inset, because moving
it across the `Center` would change the layout.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_wrapping_in_padding: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_wrapping_in_padding: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_padding_over_container`](/many_lints/docs/rules/widget-replacement/prefer-padding-over-container/) — Use Padding instead of Container when only padding or margin is set.
- [`avoid_border_all`](/many_lints/docs/rules/widget-replacement/avoid-border-all/) — Use Border.fromBorderSide instead of Border.all for const support.
- [`avoid_expanded_as_spacer`](/many_lints/docs/rules/widget-replacement/avoid-expanded-as-spacer/) — Use Spacer instead of Expanded with an empty child.
- [`avoid_incorrect_image_opacity`](/many_lints/docs/rules/widget-replacement/avoid-incorrect-image-opacity/) — Use Image's opacity parameter instead of wrapping in Opacity.
