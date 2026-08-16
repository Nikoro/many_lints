// ignore_for_file: unused_element, unused_local_variable
// ignore_for_file: many_lints/avoid_redundant_async

// prefer_explicit_type_arguments
//
// Detects a configured generic call written without explicit type arguments.
//
// This rule reports NOTHING until configured, because for most generic calls
// inference is right and explicit arguments are noise:
//
//   prefer_explicit_type_arguments:
//     methods: [showDialog, showModalBottomSheet, push, pushNamed]

Future<T?> showDialog<T>(Object builder) async => null;

// ❌ Bad
// LINT: `showDialog` infers its return type from the builder's
// `Navigator.pop(value)`, so a `pop()` with no argument silently makes this
// `Future<Null>` — and the `await` yields a null the code did not plan for.
Future<void> openBad() async {
  final result = await showDialog((_) => 1);
}

// ✅ Good: the decision moves into the signature, where a mismatch is a
// compile error rather than a runtime surprise.
Future<void> openGood() async {
  final result = await showDialog<bool>((_) => 1);
}

// Edge case: a method that is not in `methods` is left alone — inference is
// usually right, and this rule is a list of the APIs worth pinning.
Future<T?> showSheet<T>(Object builder) async => null;

Future<void> openSheet() async {
  final result = await showSheet((_) => 1);
}
