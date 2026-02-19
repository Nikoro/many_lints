// ignore_for_file: unused_field, unused_element

// avoid_public_notifier_properties
//
// Warns when a Notifier or AsyncNotifier subclass declares public properties
// (getters, fields, or setters) other than the standard `state`. All state
// should be consolidated into the `state` property using a model class.

import 'package:riverpod/riverpod.dart';

// ❌ Bad: Public getter exposes state outside the standard `state` property
class BadNotifier extends Notifier<int> {
  // LINT: Public getter — consolidate into state or make private
  int get publicGetter => 0;

  @override
  int build() => 0;
}

// ❌ Bad: Public field on a Notifier
class BadNotifier2 extends Notifier<int> {
  // LINT: Public field — consolidate into state or make private
  int publicField = 0;

  @override
  int build() => 0;
}

// ❌ Bad: Public setter on a Notifier
class BadNotifier3 extends Notifier<int> {
  int _value = 0;

  // LINT: Public setter — consolidate into state or make private
  set publicSetter(int value) => _value = value;

  @override
  int build() => _value;
}

// ✅ Good: Use a model class to consolidate state
class MyState {
  final int left;
  final int right;
  MyState(this.left, this.right);
}

class GoodNotifier extends Notifier<MyState> {
  @override
  MyState build() => MyState(0, 1);
}

// ✅ Good: Private properties are fine
class GoodNotifier2 extends Notifier<int> {
  int _privateField = 0;
  int get _privateGetter => _privateField;

  @override
  int build() => _privateGetter;
}

// ✅ Good: Public methods are allowed (only properties are flagged)
class GoodNotifier3 extends Notifier<int> {
  void increment() => state++;

  @override
  int build() => 0;
}

// ✅ Good: Static properties are fine
class GoodNotifier4 extends Notifier<int> {
  static int staticField = 0;
  static int get staticGetter => staticField;

  @override
  int build() => 0;
}
