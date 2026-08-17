---
title: pass_existing_stream_to_stream_builder
description: "Don't create a new Stream inline inside StreamBuilder"
sidebar:
  label: pass_existing_stream_to_stream_builder
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule flags a `StreamBuilder` whose `stream:` argument creates a new `Stream` inline — a method call, a `Stream` constructor, or an immediately invoked generator.

## Why use this rule

Every `build()` re-evaluates the `stream:` argument. When that argument creates a stream, the `StreamBuilder` cancels its old subscription and opens a new one on each rebuild.

For a single-subscription stream this is worse than the `FutureBuilder` equivalent: events buffered before the resubscription are lost outright, the snapshot resets to its initial state, and the discarded subscription may keep its source alive. With a socket or a database watcher, this means reconnecting on every frame.

Create the stream once and pass the same instance — a field assigned in `initState`, or a value held by your state manager.

**See also:** [StreamBuilder API docs](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html)

## Don't

```dart
Widget build(BuildContext context) {
  return StreamBuilder<int>(
    // A new subscription on every rebuild — drops events
    stream: repository.watchCounter(),
    builder: (context, snapshot) => Text('${snapshot.data}'),
  );
}
```

## Do

```dart
class _MyWidgetState extends State<MyWidget> {
  late final Stream<int> _counter;

  @override
  void initState() {
    super.initState();
    // Subscribed once, kept across rebuilds
    _counter = repository.watchCounter();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _counter,
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
  }
}
```

## Known limitations

The rule reports only expressions that certainly allocate: constructor calls, method invocations, and invoked closures. A bare identifier, a property access, or anything it cannot resolve is treated as an existing instance and left alone. A getter that creates a new stream on each access will therefore not be flagged.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`pass_existing_stream_to_stream_builder: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  pass_existing_stream_to_stream_builder: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`pass_existing_future_to_future_builder`](/many_lints/docs/rules/widget-best-practices/pass-existing-future-to-future-builder/) — Don't create a new Future inline inside FutureBuilder.
- [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/) — Don't create a GlobalKey inside build.
- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
- [`avoid_deep_widget_nesting`](/many_lints/docs/rules/widget-best-practices/avoid-deep-widget-nesting/) — Keep a widget tree within a nesting budget.
