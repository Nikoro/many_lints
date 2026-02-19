// ignore_for_file: unused_field, unused_element

// avoid_notifier_constructors
//
// Warns when a Notifier or AsyncNotifier subclass declares a constructor
// with a non-empty body or initializer list. Initialization logic should
// go into the build() method instead.

import 'package:riverpod/riverpod.dart';

// ❌ Bad: Constructor with body
class BadCounter extends Notifier<int> {
  var _initial = 0;

  // LINT: Constructor body should be empty — move logic to build()
  BadCounter() {
    _initial = 1;
  }

  @override
  int build() => _initial;
}

// ❌ Bad: Constructor with initializer list
class BadCounter2 extends Notifier<int> {
  final int _initial;

  // LINT: Initializer list in Notifier constructor — move logic to build()
  BadCounter2() : _initial = 1;

  @override
  int build() => _initial;
}

// ❌ Bad: AsyncNotifier with constructor body
class BadAsyncCounter extends AsyncNotifier<int> {
  var _initial = 0;

  // LINT: Constructor body should be empty — move logic to build()
  BadAsyncCounter() {
    _initial = 1;
  }

  @override
  Future<int> build() async => _initial;
}

// ✅ Good: No constructor, initialization in build()
class GoodCounter extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

// ✅ Good: Empty constructor is fine
class GoodCounter2 extends Notifier<int> {
  GoodCounter2();

  @override
  int build() => 0;
}
