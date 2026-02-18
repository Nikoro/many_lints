// ignore_for_file: unused_local_variable

// avoid_unassigned_stream_subscriptions
//
// Warns when a Stream.listen() call is not assigned to a variable.
// Without storing the StreamSubscription, you cannot cancel it later,
// which may lead to memory leaks.

import 'dart:async';

// ❌ Bad: Stream subscription is not stored
class BadExamples {
  void example() {
    final stream = Stream.fromIterable([1, 2, 3]);

    // LINT: Subscription not assigned — cannot cancel later
    stream.listen((event) {
      print(event);
    });
  }

  void broadcastExample() {
    final controller = StreamController<int>.broadcast();

    // LINT: Broadcast stream subscription not assigned
    controller.stream.listen((event) {
      print(event);
    });
  }
}

// ✅ Good: Stream subscription is properly stored
class GoodExamples {
  void example() {
    final stream = Stream.fromIterable([1, 2, 3]);

    // Assigned to a variable — can be cancelled later
    final subscription = stream.listen((event) {
      print(event);
    });
    subscription.cancel();
  }

  StreamSubscription<int> returnedExample() {
    final stream = Stream.fromIterable([1, 2, 3]);

    // Returned from function — caller can manage the subscription
    return stream.listen((event) {
      print(event);
    });
  }

  void passedAsArgument(List<StreamSubscription> subscriptions) {
    final stream = Stream.fromIterable([1, 2, 3]);

    // Passed as argument — managed elsewhere
    subscriptions.add(
      stream.listen((event) {
        print(event);
      }),
    );
  }
}
