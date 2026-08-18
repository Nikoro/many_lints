// ignore_for_file: many_lints/avoid_commented_out_code, many_lints/prefer_correct_error_name, many_lints/prefer_primary_constructors

// avoid_exit_outside_entrypoint
//
// Warns when `dart:io`'s `exit()` is called outside the entrypoint.
// By default only `bin/**` is allowed. This file sits in `lib/`, so the
// calls below are reported.

import 'dart:io';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

// ❌ Bad: a test reaching this line dies mid-assertion, reporting nothing
void bad(int statusCode) {
  if (statusCode == 403) {
    stderr.writeln('Permission denied');
    // LINT: terminates the process, including a test running this code
    exit(3);
  }
}

// LINT: a tear-off reaches the same place, one call later
void badTearOff() {
  onFailure(exit);
}

// ✅ Good: throw a typed error and let the entrypoint choose the exit code
void good(int statusCode) {
  if (statusCode == 403) {
    throw const AuthFailure('Permission denied');
  }
}

// The branch above is now testable:
//
//   test('a 403 is an auth failure', () {
//     expect(() => good(403), throwsA(isA<AuthFailure>()));
//   });
//
// while `bin/tool.dart` does the mapping:
//
//   try {
//     await upload(artifact);
//   } on AuthFailure catch (e) {
//     stderr.writeln(e.message);
//     exit(3);
//   }

// Edge cases: not reported — neither resolves to `dart:io`'s `exit`.
void edgeCases() {
  Terminal().exit(3);

  void exit(int code) {}
  exit(3);
}

class Terminal {
  void exit(int code) {}
}

void onFailure(void Function(int) handler) {}
