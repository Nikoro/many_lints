// ignore_for_file: unused_element, unused_field, unused_local_variable

/// Examples of the `prefer_async_callback` lint rule.

// ❌ Bad: Using verbose Future<void> Function() type
class BadWidget {
  final Future<void> Function() onTap; // LINT
  final Future<void> Function()? onLongPress; // LINT

  const BadWidget(this.onTap, this.onLongPress);
}

void badParameter(Future<void> Function() callback) {} // LINT

void badVariable() {
  Future<void> Function() callback = () async {}; // LINT
}

void badTypeArgument() {
  List<Future<void> Function()> callbacks = []; // LINT
}

Future<void> Function() badReturnType() {
  // LINT
  return () async {};
}

// ✅ Good: Using AsyncCallback typedef
// import 'package:flutter/foundation.dart';
class GoodWidget {
  // final AsyncCallback onTap;
  // final AsyncCallback? onLongPress;

  const GoodWidget();
}

// ✅ Good: Function types that are NOT AsyncCallback (different return/params)
void goodFutureInt(Future<int> Function() callback) {}
void goodFutureString(Future<String> Function() callback) {}
void goodWithParams(Future<void> Function(int value) callback) {}
void goodVoidCallback(void Function() callback) {}
