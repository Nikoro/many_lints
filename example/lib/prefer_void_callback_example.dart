// ignore_for_file: unused_element, unused_field, unused_local_variable

/// Examples of the `prefer_void_callback` lint rule.

// ❌ Bad: Using verbose void Function() type
class BadWidget {
  final void Function() onTap; // LINT
  final void Function()? onLongPress; // LINT

  const BadWidget(this.onTap, this.onLongPress);
}

void badParameter(void Function() callback) {} // LINT

void badVariable() {
  void Function() callback = () {}; // LINT
}

void badTypeArgument() {
  List<void Function()> callbacks = []; // LINT
}

void Function() badReturnType() {
  // LINT
  return () {};
}

// ✅ Good: Using VoidCallback typedef
// import 'dart:ui';
class GoodWidget {
  // final VoidCallback onTap;
  // final VoidCallback? onLongPress;

  const GoodWidget();
}

// ✅ Good: Function types that are NOT VoidCallback (different return/params)
void goodWithParams(void Function(int value) callback) {}
void goodIntReturn(int Function() callback) {}
void goodFutureReturn(Future<void> Function() callback) {}
void goodGeneric(void Function<T>() callback) {}
