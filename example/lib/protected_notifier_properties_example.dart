// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// protected_notifier_properties
//
// Warns when a Notifier's `state`, `stateOrNull`, `future` or `ref` are
// accessed from outside the notifier itself. These are part of the notifier's
// internal API — going through the provider gives correct reactivity and keeps
// state transitions in one place.

import 'package:riverpod/riverpod.dart';

class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  // ✅ Good: The notifier uses its own members freely
  void increment() => state = state + 1;
}

final counterProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);

// ❌ Bad: Reading state from outside the notifier
void badRead(CounterNotifier notifier) {
  // LINT: Read through the provider instead
  print(notifier.state);
}

// ❌ Bad: Writing state from outside the notifier
void badWrite(CounterNotifier notifier) {
  // LINT: Move the transition into a method on the notifier
  notifier.state = 1;
}

// ❌ Bad: Reaching for the notifier's ref
void badRef(CounterNotifier notifier) {
  // LINT: `ref` is internal to the notifier
  print(notifier.ref);
}

// ✅ Good: Read the value through its provider
void goodRead(Ref ref) {
  print(ref.watch(counterProvider));
}

// ✅ Good: Mutate through a method the notifier exposes
void goodWrite(Ref ref) {
  ref.read(counterProvider.notifier).increment();
}
