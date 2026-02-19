// ignore_for_file: unused_local_variable, unused_element

// use_ref_and_state_synchronously
//
// Warns when `ref` or `state` is accessed after an `await` point in a
// Riverpod Notifier without first checking `ref.mounted`. If the notifier
// is disposed before the async operation completes, accessing `ref` or
// `state` will throw an `UnmountedRefException`.

import 'package:riverpod/riverpod.dart';

// ❌ Bad: Accessing ref after await without a mounted guard
class _BadRefAfterAwait extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> incrementDelayed() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    // LINT: ref may be unmounted after the await
    ref.read(someProvider);
  }
}

// ❌ Bad: Assigning state after await without a mounted guard
class _BadStateAfterAwait extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> incrementDelayed() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    // LINT: notifier may be disposed, state access crashes
    state = state + 1;
  }
}

// ✅ Good: Using ref.mounted guard before accessing ref/state
class _GoodMountedGuard extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> incrementDelayed() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!ref.mounted) return;
    state = state + 1;
  }
}

// ✅ Good: Accessing ref/state before await (no async gap)
class _GoodBeforeAwait extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> incrementDelayed() async {
    final current = state;
    ref.read(someProvider);
    await Future<void>.delayed(const Duration(seconds: 1));
    // No ref/state access after await — safe
  }
}

// ✅ Good: Using ref/state in a sync method (no async gap)
class _GoodSyncMethod extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state = state + 1;
    ref.read(someProvider);
  }
}

final someProvider = Provider<String>((ref) => 'hello');
