// ignore_for_file: unused_element, unused_field
// ignore_for_file: many_lints/prefer_primary_constructors
// ignore_for_file: many_lints/prefer_void_callback
// ignore_for_file: many_lints/member_ordering

// prefer_correct_callback_field_name
//
// Warns when a callback is named `somethingCallback` rather than
// `onSomething`, the spelling Flutter uses throughout its API.

// ❌ Bad: says it is a callback without saying when it fires
class BadButton {
  // LINT: `BadButton(tapCallback: ...)` reads as a value, not an event
  final void Function() tapCallback;

  // LINT: same for a handler
  final void Function() submitHandler;

  const BadButton(this.tapCallback, this.submitHandler);
}

// ✅ Good: the call site reads as an event
class GoodButton {
  final void Function() onTap;
  final void Function(String) onChanged;

  const GoodButton({required this.onTap, required this.onChanged});
}

// ✅ Edge case: a function named for what it computes, not when it fires.
// Renaming either of these to `on...` would be wrong.
class GoodBuilders {
  final String Function() builder;
  final int Function(int, int) comparator;

  const GoodBuilders(this.builder, this.comparator);
}

// ✅ Edge case: a bare framework noun is the thing itself. `handler` here is
// the request handler, not a callback for an event.
typedef Handler = void Function();

Handler middleware(Handler handler) => handler;
// ignore_for_file: many_lints/prefer_typedefs_for_callbacks
