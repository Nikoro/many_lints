/// Shared [TypeChecker] constants for `package:fpdart`.
///
/// Every checker pins the *declaring* library rather than the `fpdart.dart`
/// barrel, because [TypeChecker.fromUrl] matches `element.library.identifier`
/// — the library a type is declared in, not the one an import went through.
/// fpdart declares each type in its own file under `lib/src/` and re-exports
/// the lot from `fpdart.dart`, so pinning the barrel would match nothing.
///
/// Verified against fpdart 1.2.0.
library;

import './type_checker.dart';

/// TypeChecker for `Option<T>` — a value that may be absent.
const optionChecker = TypeChecker.fromUrl(
  'package:fpdart/src/option.dart#Option',
);

/// TypeChecker for `Either<L, R>` — a synchronous computation that may fail.
const eitherChecker = TypeChecker.fromUrl(
  'package:fpdart/src/either.dart#Either',
);

/// TypeChecker for `Task<A>` — an async computation that cannot fail.
const taskChecker = TypeChecker.fromUrl('package:fpdart/src/task.dart#Task');

/// TypeChecker for `TaskEither<L, R>` — an async computation that may fail.
///
/// The workhorse of most fpdart codebases, and the type most rules here care
/// about.
const taskEitherChecker = TypeChecker.fromUrl(
  'package:fpdart/src/task_either.dart#TaskEither',
);

/// TypeChecker for `TaskOption<R>` — an async computation that may find
/// nothing.
const taskOptionChecker = TypeChecker.fromUrl(
  'package:fpdart/src/task_option.dart#TaskOption',
);

/// TypeChecker for `IO<A>` — a synchronous effect that cannot fail.
const ioChecker = TypeChecker.fromUrl('package:fpdart/src/io.dart#IO');

/// TypeChecker for `IOEither<L, R>` — a synchronous effect that may fail.
const ioEitherChecker = TypeChecker.fromUrl(
  'package:fpdart/src/io_either.dart#IOEither',
);

/// TypeChecker for `IOOption<R>` — a synchronous effect that may find nothing.
const ioOptionChecker = TypeChecker.fromUrl(
  'package:fpdart/src/io_option.dart#IOOption',
);

/// TypeChecker for `Unit` — fpdart's composable stand-in for `void`.
const unitChecker = TypeChecker.fromUrl('package:fpdart/src/unit.dart#Unit');

/// TypeChecker matching every **lazy** fpdart type — the ones that describe a
/// computation instead of performing one, and so do nothing at all until
/// `.run()` is called.
///
/// This is the set `avoid_unrun_task` guards: dropping a value of any of these
/// types on the floor silently skips the work it describes. `Option` and
/// `Either` are deliberately absent — they are already-computed values, so
/// discarding one wastes a result but never skips an effect.
const lazyFpdartChecker = TypeChecker.any([
  taskChecker,
  taskEitherChecker,
  taskOptionChecker,
  ioChecker,
  ioEitherChecker,
  ioOptionChecker,
]);

/// TypeChecker matching the two types that carry a failure in their left
/// channel and are therefore chained with `flatMap` / `mapLeft`.
const failableFpdartChecker = TypeChecker.any([
  eitherChecker,
  taskEitherChecker,
  ioEitherChecker,
]);

/// TypeChecker matching every fpdart wrapper type.
///
/// Used by rules that need to know "is this expression inside an fpdart
/// pipeline at all", regardless of which wrapper it is.
const anyFpdartChecker = TypeChecker.any([
  optionChecker,
  eitherChecker,
  taskChecker,
  taskEitherChecker,
  taskOptionChecker,
  ioChecker,
  ioEitherChecker,
  ioOptionChecker,
]);
