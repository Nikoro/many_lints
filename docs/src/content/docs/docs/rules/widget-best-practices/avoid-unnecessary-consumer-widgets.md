---
title: avoid_unnecessary_consumer_widgets
description: "Don't extend ConsumerWidget if you never use WidgetRef"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_consumer_widgets
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a Riverpod consumer widget that never touches its `ref`.

A consumer subscribes to the provider container and joins the dependency graph whether or not it reads anything from it. Dropping back to `StatelessWidget` removes that, and makes the widget's dependencies visible in its declaration: it has none.

Covers `ConsumerWidget`, `ConsumerStatefulWidget` and `HookConsumerWidget`. The quick fix rewrites the base class and removes the unused `ref` parameter.

This rule is in the **`opinionated`** preset, so it is on with `preset: opinionated` and `preset: pedantic`. No configuration.

**See also:** [Riverpod consumers](https://riverpod.dev/docs/concepts2/consumers)

## Don't

The usual origin: the `ref.watch` moved to the parent, and the base class was left as it was.

```dart
class Greeting extends ConsumerWidget {
  const Greeting({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

### A stateful consumer is judged on the whole State class

`ConsumerStatefulWidget` keeps its `ref` as a getter on the companion `ConsumerState`, not as a `build` parameter — so a `ref` used in `initState`, a lifecycle method or an event handler counts just as much as one used in `build`:

```dart
// Not reported: the ref is used, just not in build
class _EditPageState extends ConsumerState<EditPage> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).log('opened');
  }

  @override
  Widget build(BuildContext context) => const Text('Edit');
}
```

### A ref used through a mixin counts

Sharing provider access through a mixin leaves the state body looking ref-free while the widget genuinely needs the container. That is recognised and not reported:

```dart
mixin AnalyticsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  void track(String event) {
    ref.read(analyticsProvider).log(event);
  }
}

class _EditPageState extends ConsumerState<EditPage> with AnalyticsMixin {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => track('saved'),
      child: const Text('Save'),
    );
  }
}
```

For a mixin declared in another file, the recognition is by its `on ConsumerState<T>` constraint — that constraint is why it can reach a `ref` at all.

### HookConsumerWidget becomes a HookWidget

It drops only the Riverpod half; the `build` may still call hooks, so the fix does not go all the way to `StatelessWidget`:

```dart
// Don't
class Counter extends HookConsumerWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = useState(0);
    return Text('${count.value}');
  }
}

// Do
class Counter extends HookWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useState(0);
    return Text('${count.value}');
  }
}
```

A `HookConsumerWidget` using neither hooks nor `ref` is reported here *and* by [`avoid_unnecessary_hook_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-hook-widgets/) — the two answer different questions and each points at a different node.

## Known limitations

Usage is detected by the **name** `ref`, anywhere in the relevant body. A widget that renames its parameter, or one whose body happens to mention an unrelated `ref`, is judged on the name rather than on resolution.

A `ConsumerWidget` whose `build` has no `ref` parameter at all is not reported — there is nothing to remove.

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_consumer_widgets: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_returning_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-returning-widgets/) — Extract widget helper methods into separate widget classes.
- [`avoid_single_child_in_multi_child_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-single-child-in-multi-child-widgets/) — Don't use Column, Row, or other multi-child widgets with only one child.
- [`avoid_too_many_widgets_per_build`](/many_lints/docs/rules/widget-best-practices/avoid-too-many-widgets-per-build/) — Keep one build method within a widget budget.
- [`avoid_unnecessary_hook_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-hook-widgets/) — Don't extend HookWidget if you never call any hooks.
