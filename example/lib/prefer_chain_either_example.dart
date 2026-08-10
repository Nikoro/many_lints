// ignore_for_file: unused_element, unused_local_variable

// prefer_chain_either
//
// `chainEither` is `flatMap` for a synchronous failable step: it takes the
// `Either`-returning function directly and lifts it for you. Doing the lift by
// hand re-implements it, and in a run of validators it is pure noise.

import 'package:fpdart/fpdart.dart';

Either<String, int> _decode(String body) => Either.of(body.length);

void _log(String message) {}

TaskEither<String, String> _fetch() => TaskEither.of('body');

// ❌ Bad: the callback's whole job is the lift
TaskEither<String, int> badExpressionBody() =>
    // LINT: use chainEither
    _fetch().flatMap((body) => _decode(body).toTaskEither());

// ❌ Bad: same thing in block form
TaskEither<String, int> badBlockBody() =>
    // LINT: use chainEither
    _fetch().flatMap((body) {
      return _decode(body).toTaskEither();
    });

// ✅ Good: the step is passed straight through
TaskEither<String, int> goodChainEither() => _fetch().chainEither(_decode);

// ✅ Good: the callback does more than lift, so rewriting would drop the log
TaskEither<String, int> goodCallbackDoesMore() => _fetch().flatMap((body) {
  _log(body);
  return _decode(body).toTaskEither();
});

// ✅ Good: a genuinely async step belongs in flatMap
TaskEither<String, int> goodAsyncStep() =>
    _fetch().flatMap((body) => TaskEither.of(body.length));
