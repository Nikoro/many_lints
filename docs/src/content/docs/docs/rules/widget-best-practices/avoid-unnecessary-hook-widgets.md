---
title: avoid_unnecessary_hook_widgets
description: "Don't extend HookWidget if you never call any hooks"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_hook_widgets
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a `HookWidget` whose `build` calls no hook, and a `HookBuilder` whose `builder` calls none.

`HookWidget` installs a hook-management layer over the normal widget lifecycle. With no hooks that layer is pure overhead, and the class advertises state management that is not there. The quick fix rewrites the superclass to `StatelessWidget`.

This rule is in the **`opinionated`** preset, so it is on with `preset: opinionated` and `preset: pedantic`. No configuration.

**See also:** [flutter_hooks](https://pub.dev/packages/flutter_hooks)

## Don't

The common way in is a refactor: the `useState` moved up to the parent and nobody changed the base class back.

```dart
class Greeting extends HookWidget {
  const Greeting({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text('Hello $name');
  }
}
```

## Do

```dart
class Greeting extends StatelessWidget {
  const Greeting({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text('Hello $name');
  }
}
```

### An empty HookBuilder

A `HookBuilder` exists to open a hook scope for a small part of a tree. One whose body calls no hook is a `Builder` with extra machinery:

```dart
// Don't
HookBuilder(
  builder: (context) => const Text('Static'),
);

// Do
Builder(
  builder: (context) => const Text('Static'),
);
```

## Known limitations

Only a class whose `extends` clause names `HookWidget` or `HookConsumerWidget` **directly** is checked. A subclass of your own `AppHookWidget` base is not.

Hook detection is by name — an identifier matching `use` followed by a capital or a digit, optionally prefixed with `_`. A helper of your own called `useFormatting()` that is not really a hook therefore keeps the widget quiet.

A `HookConsumerWidget` that uses neither hooks nor `ref` is reported here *and* by [`avoid_unnecessary_consumer_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-consumer-widgets/). The two answer different questions and point at different nodes.

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_hook_widgets: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
- [`avoid_hooks_outside_build`](/many_lints/docs/rules/hook-rules/avoid-hooks-outside-build/) — Only call hooks from a hook context.
- [`avoid_misused_hooks`](/many_lints/docs/rules/hook-rules/avoid-misused-hooks/) — Don't call hooks inside loops.
- [`avoid_returning_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-returning-widgets/) — Extract widget helper methods into separate widget classes.
