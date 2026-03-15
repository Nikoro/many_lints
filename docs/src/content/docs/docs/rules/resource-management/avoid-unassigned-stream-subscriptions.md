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

**See also:** [Dart - Streams](https://dart.dev/libraries/async/using-streams) | [StreamSubscription](https://api.dart.dev/stable/dart-async/StreamSubscription-class.html)

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
