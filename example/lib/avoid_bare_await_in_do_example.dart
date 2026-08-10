// ignore_for_file: unused_element, unused_local_variable

// avoid_bare_await_in_do
//
// `$` is what makes a failing step short-circuit a `Do` block. A bare
// `await someFuture` bypasses it: the future runs outside the block's control,
// and a failure escapes as an ordinary exception past every fold.

import 'package:fpdart/fpdart.dart';

Future<int> _loadRaw() async => 1;

TaskEither<String, int> _loadWrapped() => TaskEither.of(1);

// ❌ Bad: the future escapes the block's tracking
TaskEither<String, int> badBareAwait() => TaskEither.Do(($) async {
  // LINT: wrap it in an fpdart type and extract it with `$`
  await _loadRaw();
  return 1;
});

// ✅ Good: wrapped, so a failure becomes a Left and aborts the block
TaskEither<String, int> goodWrapped() => TaskEither.Do(($) async {
  final value = await $(
    TaskEither.tryCatch(_loadRaw, (error, stackTrace) => error.toString()),
  );
  return value;
});

// ✅ Good: extracting an existing TaskEither
TaskEither<String, int> goodExtracted() => TaskEither.Do(($) async {
  final value = await $(_loadWrapped());
  return value;
});

// ✅ Good: a closure declared in the body has its own async context, so its
// await was never one of the block's tracked steps
TaskEither<String, int> goodAwaitInClosure() => TaskEither.Do(($) async {
  Future<int> Function() later = () async => await _loadRaw();
  return await $(_loadWrapped());
});

// ✅ Good: synchronous blocks cannot hit this at all
Option<String> goodSyncBlock(Option<String> o) => Option.Do(($) => $(o));
