// ignore_for_file: many_lints/prefer_correct_error_name, many_lints/prefer_primary_constructors, many_lints/prefer_void_callback

// prefer_typed_exceptions
//
// Warns when a throw does not name a type a caller could catch selectively.
// A bare `Exception('...')` can only be distinguished by its message text.

class Failure {
  const Failure(this.message);

  final String message;
}

class UploadFailure implements Exception {
  const UploadFailure(this.message);

  final String message;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

// ❌ Bad: nothing downstream can catch just this failure
void bad(int port) {
  // LINT: every `on Exception` in the program matches this
  throw Exception('upload failed');

  // LINT: not even an Exception
  // ignore: only_throw_errors
  throw 'upload failed';

  // LINT: a domain object that forgot to implement Exception is just as opaque
  // ignore: only_throw_errors
  throw const Failure('upload failed');
}

// ✅ Good: the type is the thing a caller matches on
void good(int port) {
  throw const UploadFailure('upload failed');
}

// Edge cases: not reported.
void edgeCases(int port) {
  // SDK types whose own name identifies the failure are allowed by default.
  throw ArgumentError.value(port, 'port', 'must be positive');
}

// The payoff: a caller can now map each failure onto its own behaviour.
int exitCodeFor(void Function() action) {
  try {
    action();
    return 0;
  } on AuthFailure {
    return 3;
  } on UploadFailure {
    return 4;
  }
}
