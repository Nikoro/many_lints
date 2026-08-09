---
title: avoid_unassigned_stream_subscriptions
description: "Ensure stream subscriptions are assigned to a variable for proper cancellation."
sidebar:
  label: avoid_unassigned_stream_subscriptions
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Resource Management</span>

Flags `Stream.listen()` calls whose return value (a `StreamSubscription`) is not assigned to a variable, returned, or passed as an argument. Without storing the subscription, you have no way to cancel it later, which leads to memory leaks and unexpected behavior.

## Why use this rule

A `StreamSubscription` that is never stored cannot be cancelled. The listener keeps running indefinitely, holding references to the callback closure and everything it captures. This is especially problematic in StatefulWidgets where the stream may outlive the widget, causing `setState()` calls on a disposed State.

**See also:** [Dart - Streams](https://dart.dev/libraries/async/using-streams) | [StreamSubscription](https://api.dart.dev/stable/dart-async/StreamSubscription-class.html) | [Dart lint: cancel_subscriptions](https://dart.dev/tools/linter-rules/cancel_subscriptions)

## Don't

```dart
void example() {
  final stream = Stream.fromIterable([1, 2, 3]);

  // Subscription not assigned -- cannot cancel later
  stream.listen((event) {
    print(event);
  });
}
```

## Do

```dart
void example() {
  final stream = Stream.fromIterable([1, 2, 3]);

  // Assigned to a variable -- can be cancelled later
  final subscription = stream.listen((event) {
    print(event);
  });
  subscription.cancel();
}

// Returning the subscription is also fine:
StreamSubscription<int> listen(Stream<int> stream) {
  return stream.listen((event) => print(event));
}

// Passing as an argument is also fine:
void track(List<StreamSubscription> subs, Stream<int> stream) {
  subs.add(stream.listen((event) => print(event)));
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unassigned_stream_subscriptions: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  avoid_unassigned_stream_subscriptions:
    ignored_instances: [eventBus]
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ignored_instances` | list of strings | `[]` | Receiver expressions whose subscriptions are torn down centrally |

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
