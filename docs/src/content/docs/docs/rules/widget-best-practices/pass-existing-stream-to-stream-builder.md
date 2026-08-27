---
title: pass_existing_stream_to_stream_builder
description: "Don't create a new Stream inline inside StreamBuilder"
sidebar:
  label: pass_existing_stream_to_stream_builder
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a `StreamBuilder` whose `stream:` argument creates a new `Stream` — a method call, a `Stream` constructor, or an immediately invoked generator.

Every `build()` re-evaluates the argument. When it creates a stream, the `StreamBuilder` cancels its old subscription and opens a new one.

For a single-subscription stream this is worse than the `FutureBuilder` case: events buffered before the resubscription are lost outright, the snapshot resets to its initial state, and the discarded subscription may keep its source alive. With a socket or a database watcher this means reconnecting on every frame.

This rule is in the **`recommended`** preset, so it is on with `preset: recommended` and every preset above it. No configuration.

**See also:** [StreamBuilder API docs](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html)

## Don't

```dart
@override
Widget build(BuildContext context) {
  return StreamBuilder<int>(
    // A new subscription on every rebuild — drops buffered events
    stream: watchCounter(),
    builder: (context, snapshot) => Text('${snapshot.data}'),
  );
}
```

## Do

Open it once in `initState` and pass the same instance:

```dart
class _CounterPageState extends State<CounterPage> {
  late final Stream<int> _counter;

  @override
  void initState() {
    super.initState();
    _counter = watchCounter();
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

### Broadcast streams still lose events

Making the stream a broadcast stream stops the "already listened to" error, but does not fix this — a broadcast stream does not replay what it emitted before the new subscription arrived. Cache the stream itself, not just its type:

```dart
// Don't — still resubscribes, still misses everything emitted in between
StreamBuilder<int>(
  stream: watchCounter().asBroadcastStream(),
  builder: (context, snapshot) => Text('${snapshot.data}'),
);
```

### The other shapes that allocate

```dart
// Don't
StreamBuilder<int>(
  stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
  builder: (context, snapshot) => const SizedBox(),
);

StreamBuilder<int>(
  stream: Stream.fromIterable(const [1, 2, 3]),
  builder: (context, snapshot) => const SizedBox(),
);
```

## Known limitations

Only expressions that certainly allocate are reported: constructor calls, method invocations, and invoked closures. A bare identifier, a property access, a ternary, or anything unresolved is treated as an existing instance and left alone.

A getter that creates a new stream on each access is therefore not flagged, though it has the same problem:

```dart
// Not reported, but resubscribes on every rebuild all the same
Stream<int> get counter => watchCounter();

Widget build(BuildContext context) => StreamBuilder<int>(
      stream: counter,
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
```

## Turning this rule off

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
