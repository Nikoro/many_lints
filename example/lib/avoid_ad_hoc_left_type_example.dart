// ignore_for_file: unused_element, unused_local_variable

// avoid_ad_hoc_left_type
//
// `flatMap` only composes when every step shares one left type. Bridging a
// mismatch with `(e) => e.toString()` collapses a sealed hierarchy into a
// message, and the fold at the boundary loses the ability to switch on it.
//
// This rule reports nothing until `error_types` names the hierarchy:
//
//   rules:
//     avoid_ad_hoc_left_type:
//       error_types: [Failure]

import 'package:fpdart/fpdart.dart';

sealed class Failure {}

class NetworkFailure extends Failure {}

class AuthFailure extends Failure {}

class _User {
  const _User(this.id);
  final String id;
}

// ❌ Bad (once configured): the error channel is not part of the hierarchy
// LINT: use Failure in the error channel
TaskEither<String, _User> badStringLeft(String id) => throw '';

// ❌ Bad: same for a plain Either
// LINT: use Failure in the error channel
Either<int, String> badIntLeft() => throw '';

// ✅ Good: the shared hierarchy, so every step composes
TaskEither<Failure, _User> goodFailureLeft(String id) => throw '';

// ✅ Good: a subtype is accepted by default, so a sealed hierarchy works by
// naming only its root
TaskEither<NetworkFailure, _User> goodSubtype(String id) => throw '';

// ✅ Good: Option has no error channel to check
Option<String> goodOption() => throw '';

// ✅ Good: the fold stays exhaustive because the failure kept its structure
String goodExhaustiveFold(Either<Failure, _User> result) => result.match(
  (failure) => switch (failure) {
    NetworkFailure() => 'retry',
    AuthFailure() => 'sign out',
  },
  (user) => user.id,
);
