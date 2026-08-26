// prefer_and_then
//
// Warns when flatMap ignores the value it is handed, which is what andThen
// expresses. fpdart declares andThen as exactly `flatMap((_) => then())`, so
// the change is a rename, not a behaviour change.

import 'package:fpdart/fpdart.dart';

TaskEither<String, int> next() => throw UnimplementedError();

TaskEither<String, int> parse(String raw) => throw UnimplementedError();

// ❌ Bad: the callback ignores its argument
// LINT: use andThen
TaskEither<String, int> bad(TaskEither<String, String> pipeline) =>
    pipeline.flatMap((_) => next());

// ✅ Good
TaskEither<String, int> good(TaskEither<String, String> pipeline) =>
    pipeline.andThen(next);

// Edge case: the callback uses its argument, so the previous value matters and
// andThen would discard it.
TaskEither<String, int> usesValue(TaskEither<String, String> pipeline) =>
    pipeline.flatMap((value) => parse(value));

// Edge case: a block body is a real function, left alone.
TaskEither<String, int> blockBody(TaskEither<String, String> pipeline) =>
    pipeline.flatMap((_) {
      return next();
    });
