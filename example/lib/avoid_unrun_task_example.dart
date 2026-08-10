// ignore_for_file: unused_element, unused_local_variable

// avoid_unrun_task
//
// fpdart's lazy types describe work rather than performing it. Discarding one
// does not waste a result — it skips the operation entirely, with no error and
// nothing to see at the call site.

import 'package:fpdart/fpdart.dart';

class _User {
  const _User(this.name);
  final String name;
}

TaskEither<String, Unit> _save(_User user) => TaskEither.of(unit);

Task<int> _count() => Task.of(1);

IO<String> _readConfig() => IO.of('config');

// ❌ Bad: the save never happens — no request, no error, nothing
void badDiscardedTaskEither(_User user) {
  // LINT: call .run() on it, or return it
  _save(user);
}

// ❌ Bad: same for a Task
void badDiscardedTask() {
  // LINT: call .run() on it, or return it
  _count();
}

// ❌ Bad: and for a synchronous IO effect
void badDiscardedIo() {
  // LINT: call .run() on it, or return it
  _readConfig();
}

// ✅ Good: run it and await the result
Future<void> goodAwaited(_User user) async {
  await _save(user).run();
}

// ✅ Good: return it, so the caller decides when to run it
TaskEither<String, Unit> goodReturned(_User user) => _save(user);

// ✅ Good: assigned, then run
Future<void> goodAssigned(_User user) async {
  final task = _save(user);
  await task.run();
}

// ✅ Good: Either and Option are already-computed values, so discarding one
// wastes a result but never skips an effect — they are not reported
Either<String, int> _compute() => Either.of(1);

void goodEitherDiscarded() {
  _compute();
}
