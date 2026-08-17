// ignore_for_file: unused_element, unused_local_variable, avoid_print

// prefer_task_either_over_try_catch
//
// A repository's failures are part of its contract. `Future<User>` promises
// they are not, and the try/catch inside either swallows the error or rethrows
// something the caller still cannot see coming.

import 'package:fpdart/fpdart.dart';

class _User {
  const _User(this.id);
  final String id;
}

Future<_User> _fetch(String id) async => _User(id);

// ❌ Bad: the failure is invisible in the signature
class UserRepository {
  // LINT: return TaskEither<Failure, T>
  Future<_User> load(String id) async {
    try {
      return await _fetch(id);
    } catch (e) {
      rethrow;
    }
  }
}

// ✅ Good: the failure is part of the type
class GoodUserRepository {
  TaskEither<String, _User> load(String id) => TaskEither.tryCatch(
    () => _fetch(id),
    (error, stackTrace) => error.toString(),
  );
}

// ✅ Good: a synchronous failable method is Either's job
class SyncRepository {
  Either<String, int> parse(String raw) =>
      Either.tryCatch(() => int.parse(raw), (e, s) => e.toString());
}

// ✅ Good: try/finally is cleanup, not failure handling
class CleanupRepository {
  Future<_User> load(String id) async {
    try {
      return await _fetch(id);
    } finally {
      print('done');
    }
  }
}

// ✅ Good: not a boundary class, so catching here is often exactly right
class Helper {
  Future<_User> load(String id) async {
    try {
      return await _fetch(id);
    } catch (e) {
      rethrow;
    }
  }
}
// ignore_for_file: many_lints/avoid_only_rethrow
// ignore_for_file: many_lints/prefer_primary_constructors
// ignore_for_file: many_lints/prefer_returning_shorthands
