// ignore_for_file: unused_element, many_lints/prefer_returning_shorthands

// avoid_chain_first_swallowing_failure
//
// fpdart's `chainFirst` runs an effect and keeps the original value, but it
// also turns a failing effect back into success. A check or a write chained
// this way can fail without anyone noticing.

import 'package:fpdart/fpdart.dart';

TaskEither<String, int> loadUser(int id) => TaskEither.right(id);

TaskEither<String, Unit> saveUser(int user) =>
    TaskEither.left('database unavailable');

Either<String, Unit> checkOwner(int user) => Either.left('not your record');

// ❌ Bad: the save fails, and the pipeline still succeeds
TaskEither<String, int> badTearOff(int id) =>
    // LINT: chainFirst discards the failure of saveUser
    loadUser(id).chainFirst(saveUser);

// ❌ Bad: an ownership check that cannot reject anything
Either<String, int> badCheck(Either<String, int> user) =>
    // LINT: chainFirst discards the failure of checkOwner
    user.chainFirst((value) => checkOwner(value));

// ✅ Good: flatMap propagates the failure and keeps the value on success
TaskEither<String, int> goodSave(int id) =>
    loadUser(id).flatMap((user) => saveUser(user).map((_) => user));

// ✅ Good: a failing check fails the pipeline
Either<String, int> goodCheck(Either<String, int> user) =>
    user.flatMap((value) => checkOwner(value).map((_) => value));
