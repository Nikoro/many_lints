// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_void_callback

// avoid_unnecessary_call
//
// Warns when a function is invoked through an explicit .call(), where a
// direct invocation says the same thing.

// ❌ Bad: `.call` makes a plain invocation look like a method on an object
void badInvoke(void Function() onDone) {
  // LINT: `onDone()` says the same thing
  onDone.call();
}

// ✅ Good: invoked the way every other function is
void goodInvoke(void Function() onDone) {
  onDone();
}

// ✅ Edge case: `onDone?()` does not parse, so `.call` is required here.
void goodNullAware(void Function()? onDone) {
  onDone?.call();
}

// ✅ Edge case: a class defining `call` as a real method is invoking that
// method — `.call` is part of its name, not the implicit function interface.
class Api {
  void call(String endpoint) {}
}

void goodCallableClass(Api api) {
  api.call('/users');
}
