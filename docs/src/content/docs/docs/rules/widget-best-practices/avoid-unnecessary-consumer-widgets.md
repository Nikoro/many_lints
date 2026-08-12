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

This rule detects `ConsumerWidget` subclasses where the `WidgetRef` parameter is never used inside the `build` method. If you are not reading or watching any providers, there is no reason to use `ConsumerWidget` over a plain `StatelessWidget`.

The same applies to `ConsumerStatefulWidget`. There the `ref` is a getter on the companion `ConsumerState`, so the rule looks at the whole state class rather than at a `build` parameter — a `ref` used in an event handler or a lifecycle method counts just as much as one used in `build`.

`HookConsumerWidget` from `hooks_riverpod` is covered too. It drops only the Riverpod half, so the fix converts it to a `HookWidget` rather than a `StatelessWidget` — the `build` may still call hooks. A `HookConsumerWidget` that uses neither hooks nor `ref` is reported by [`avoid_unnecessary_hook_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-hook-widgets/) as well; the two diagnostics answer different questions and each points at a different node.

## Why use this rule

Every `ConsumerWidget` subscribes to the Riverpod container, which means it participates in the provider dependency graph even when it does not need to. Switching to `StatelessWidget` removes that overhead, makes the widget's dependencies explicit (it has none), and signals to other developers that this widget is purely presentational.

**See also:** [ConsumerWidget](https://riverpod.dev/docs/essentials/combining_requests)

## Don't

```dart
// ConsumerWidget with unused ref parameter
class Greeting extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref is never used
    return Text('Hello');
  }
}
```

## Do

```dart
// StatelessWidget since no providers are needed
class Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello');
  }
}
```

```dart
// A ref used by a mixin still counts: the state body looks ref-free, but the
// widget genuinely needs the Riverpod container.
mixin AnalyticsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  void track(String event) {
    ref.read(analyticsProvider).log(event);
  }
}

class EditPage extends ConsumerStatefulWidget {
  const EditPage({super.key});

  @override
  ConsumerState<EditPage> createState() => _EditPageState();
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

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_consumer_widgets: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_consumer_widgets: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
