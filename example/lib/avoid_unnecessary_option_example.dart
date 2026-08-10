// ignore_for_file: unused_element, unused_local_variable

// avoid_unnecessary_option
//
// `Option` earns its keep through its combinators. A local that is wrapped and
// then unwrapped on the next line gets none of that, and gives up Dart's own
// null-aware operators in exchange for nothing.

import 'package:fpdart/fpdart.dart';

String _deriveDisplayName(String name) => name.toUpperCase();

void _use(Option<String> option) {}

// ❌ Bad: wrapped, then immediately unwrapped
String _badWrapUnwrap(String? name) {
  // LINT: use a nullable type, or compose the Option
  final option = Option.fromNullable(name);
  return option.toNullable() ?? 'unknown';
}

// ✅ Good: the plain nullable, with the language support that comes with it
String _goodNullable(String? name) => name ?? 'unknown';

// ✅ Good: the wrapper earns its place through composition
String _goodComposed(String? name) {
  final option = Option.fromNullable(name);
  return option.map(_deriveDisplayName).getOrElse(() => 'unknown');
}

// ✅ Good: passing the Option on keeps it a value, which is a real use
void _goodPassedAlong(String? name) {
  final option = Option.fromNullable(name);
  _use(option);
}

// ✅ Good: a public member may be feeding a contract, so it is skipped by
// default. Set `ignore_public_api: false` to report it too.
String goodPublicApi(String? name) {
  final option = Option.fromNullable(name);
  return option.toNullable() ?? 'unknown';
}
