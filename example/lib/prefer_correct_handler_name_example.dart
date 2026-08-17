// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_primary_constructors
// ignore_for_file: many_lints/prefer_void_callback
// ignore_for_file: many_lints/member_ordering
// ignore_for_file: many_lints/prefer_returning_shorthands

// prefer_correct_handler_name
//
// Detects a method passed as an event handler that is not named on... or
// handle.... Only a tear-off passed to an `on...` parameter is considered.

class Button {
  Button({this.onTap});

  final void Function()? onTap;
}

// ❌ Bad: the call site reads `onTap: _submit` and the reader holds the mapping
class BadExample {
  void _submit() {}

  Button build() => Button(onTap: _submit);
}

// ✅ Good: the pairing is stated once
class GoodExample {
  void _onTap() {}

  void _handleTap() {}

  Button build() => Button(onTap: _onTap);

  Button buildOther() => Button(onTap: _handleTap);
}

// Edge cases where the lint intentionally does NOT trigger
class EdgeCases {
  void submit() {}

  // A closure is not a named handler.
  Button closure() => Button(onTap: () => submit());

  // The prefix must start a new word, so `online` does not satisfy `on`.
  void _online() {}

  // LINT: reported, because `_online` only looks on-prefixed
  Button looksPrefixed() => Button(onTap: _online);
}
// ignore_for_file: many_lints/prefer_declaring_const_constructor
