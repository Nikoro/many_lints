/// A stand-in for `package:fpdart` 1.2.0, keyed by path relative to the
/// package root.
///
/// The layout mirrors fpdart's own: each type is declared in its own
/// `lib/src/<type>.dart` and re-exported from `lib/fpdart.dart`. That is not
/// cosmetic. The rules' [TypeChecker]s pin *declaring* libraries
/// (`package:fpdart/src/task_either.dart#TaskEither`), because
/// `TypeChecker.fromUrl` matches `element.library.identifier` — where a type is
/// declared, not where an import went through. A stub that declared everything
/// in one barrel would resolve the names and match no checker, leaving every
/// rule silent and every assertion vacuously true.
///
/// Keep this stub compiling. When it fails to resolve, `Type.Do(...)` is never
/// rewritten from `MethodInvocation` to `InstanceCreationExpression`, so the
/// Do-notation rules match nothing while an AST dump still looks plausible.
/// The cheap check: extract these files to a scratch package and run
/// `dart analyze` on it.
const fpdartStubFiles = <String, String>{
  'lib/src/unit.dart': r'''

final class Unit {
  const Unit._();
}
const unit = Unit._();
''',

  'lib/src/option.dart': r'''

import 'either.dart';

typedef DoAdapterOption = A Function<A>(Option<A>);
typedef DoFunctionOption<A> = A Function(DoAdapterOption $);

sealed class Option<T> {
  const Option();
  factory Option.of(T t) = Some<T>;
  factory Option.none() = None;
  factory Option.fromNullable(T? t) => t == null ? None() : Some(t);
  factory Option.tryCatch(T Function() run) => throw '';
  factory Option.fromPredicate(T value, bool Function(T) predicate) => throw '';
  factory Option.safeCast(dynamic value) => throw '';
  static Option<T> safeCastStrict<T, V>(V value) => throw '';
  factory Option.Do(DoFunctionOption<T> f) => throw '';
  Option<B> map<B>(B Function(T t) f);
  Option<B> flatMap<B>(Option<B> Function(T t) f);
  Option<B> andThen<B>(Option<B> Function() then);
  Option<T> alt(Option<T> Function() orElse);
  T getOrElse(T Function() orElse);
  B match<B>(B Function() onNone, B Function(T t) onSome);
  Either<L, T> toEither<L>(L Function() onLeft);
  T? toNullable();
}

class Some<T> extends Option<T> {
  final T value;
  const Some(this.value);
  Option<B> map<B>(B Function(T t) f) => throw '';
  Option<B> flatMap<B>(Option<B> Function(T t) f) => throw '';
  Option<B> andThen<B>(Option<B> Function() then) => throw '';
  Option<T> alt(Option<T> Function() orElse) => throw '';
  T getOrElse(T Function() orElse) => throw '';
  B match<B>(B Function() onNone, B Function(T t) onSome) => throw '';
  Either<L, T> toEither<L>(L Function() onLeft) => throw '';
  T? toNullable() => throw '';
}

class None extends Option<Never> {
  const None();
  Option<B> map<B>(B Function(Never t) f) => throw '';
  Option<B> flatMap<B>(Option<B> Function(Never t) f) => throw '';
  Option<B> andThen<B>(Option<B> Function() then) => throw '';
  Option<Never> alt(Option<Never> Function() orElse) => throw '';
  Never getOrElse(Never Function() orElse) => throw '';
  B match<B>(B Function() onNone, B Function(Never t) onSome) => throw '';
  Either<L, Never> toEither<L>(L Function() onLeft) => throw '';
  Never toNullable() => throw '';
}

Option<T> optionOf<T>(T? t) => throw '';
Option<T> some<T>(T t) => throw '';
Option<T> none<T>() => throw '';
''',

  'lib/src/either.dart': r'''

import 'option.dart';
import 'task_either.dart';

typedef DoAdapterEither<L> = R Function<R>(Either<L, R>);
typedef DoFunctionEither<L, R> = R Function(DoAdapterEither<L> $);

sealed class Either<L, R> {
  const Either();
  factory Either.of(R r) = Right<L, R>;
  factory Either.left(L l) = Left<L, R>;
  factory Either.right(R r) = Right<L, R>;
  factory Either.tryCatch(
    R Function() run,
    L Function(Object o, StackTrace s) onError,
  ) => throw '';
  factory Either.fromNullable(R? r, L Function() onNull) => throw '';
  factory Either.fromPredicate(
    R value,
    bool Function(R) predicate,
    L Function(R) onFalse,
  ) => throw '';
  factory Either.safeCast(dynamic value, L Function(dynamic) onError) =>
      throw '';
  static Either<L, R> safeCastStrict<L, R, V>(
    V value,
    L Function(V value) onError,
  ) => throw '';
  factory Either.Do(DoFunctionEither<L, R> f) => throw '';
  Either<L, B> map<B>(B Function(R r) f);
  Either<C, R> mapLeft<C>(C Function(L l) f);
  Either<L, B> flatMap<B>(Either<L, B> Function(R r) f);
  Either<L, R> alt(Either<L, R> Function() orElse);
  Either<L, R> orElse<C>(Either<L, R> Function(L l) onLeft);
  R getOrElse(R Function(L l) orElse);
  B match<B>(B Function(L l) onLeft, B Function(R r) onRight);
  B fold<B>(B Function(L l) onLeft, B Function(R r) onRight);
  Option<R> toOption();
  TaskEither<L, R> toTaskEither();
  R? toNullable();
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
  Either<L, B> map<B>(B Function(R r) f) => throw '';
  Either<C, R> mapLeft<C>(C Function(L l) f) => throw '';
  Either<L, B> flatMap<B>(Either<L, B> Function(R r) f) => throw '';
  Either<L, R> alt(Either<L, R> Function() orElse) => throw '';
  Either<L, R> orElse<C>(Either<L, R> Function(L l) onLeft) => throw '';
  R getOrElse(R Function(L l) orElse) => throw '';
  B match<B>(B Function(L l) onLeft, B Function(R r) onRight) => throw '';
  B fold<B>(B Function(L l) onLeft, B Function(R r) onRight) => throw '';
  Option<R> toOption() => throw '';
  TaskEither<L, R> toTaskEither() => throw '';
  R? toNullable() => throw '';
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
  Either<L, B> map<B>(B Function(R r) f) => throw '';
  Either<C, R> mapLeft<C>(C Function(L l) f) => throw '';
  Either<L, B> flatMap<B>(Either<L, B> Function(R r) f) => throw '';
  Either<L, R> alt(Either<L, R> Function() orElse) => throw '';
  Either<L, R> orElse<C>(Either<L, R> Function(L l) onLeft) => throw '';
  R getOrElse(R Function(L l) orElse) => throw '';
  B match<B>(B Function(L l) onLeft, B Function(R r) onRight) => throw '';
  B fold<B>(B Function(L l) onLeft, B Function(R r) onRight) => throw '';
  Option<R> toOption() => throw '';
  TaskEither<L, R> toTaskEither() => throw '';
  R? toNullable() => throw '';
}
''',

  'lib/src/task.dart': r'''

typedef DoAdapterTask = Future<A> Function<A>(Task<A>);
typedef DoFunctionTask<A> = Future<A> Function(DoAdapterTask $);

final class Task<A> {
  final Future<A> Function() _run;
  const Task(this._run);
  factory Task.of(A a) => throw '';
  factory Task.Do(DoFunctionTask<A> f) => throw '';
  Task<B> map<B>(B Function(A a) f) => throw '';
  Task<B> flatMap<B>(Task<B> Function(A a) f) => throw '';
  Future<A> run() => _run();
}
''',

  'lib/src/task_either.dart': r'''

import 'either.dart';
import 'task.dart';

typedef DoAdapterTaskEither<E> = Future<A> Function<A>(TaskEither<E, A>);
typedef DoFunctionTaskEither<L, A> = Future<A> Function(
  DoAdapterTaskEither<L> $,
);

final class TaskEither<L, R> {
  final Future<Either<L, R>> Function() _run;
  const TaskEither(this._run);
  factory TaskEither.of(R r) => throw '';
  factory TaskEither.left(L l) => throw '';
  factory TaskEither.right(R r) => throw '';
  factory TaskEither.tryCatch(
    Future<R> Function() run,
    L Function(Object error, StackTrace stackTrace) onError,
  ) => throw '';
  factory TaskEither.fromNullable(R? r, L Function() onNull) => throw '';
  factory TaskEither.fromPredicate(
    R value,
    bool Function(R) predicate,
    L Function(R) onFalse,
  ) => throw '';
  factory TaskEither.fromEither(Either<L, R> either) => throw '';
  factory TaskEither.Do(DoFunctionTaskEither<L, R> f) => throw '';
  TaskEither<L, B> map<B>(B Function(R r) f) => throw '';
  TaskEither<C, R> mapLeft<C>(C Function(L l) f) => throw '';
  TaskEither<L, B> flatMap<B>(TaskEither<L, B> Function(R r) f) => throw '';
  TaskEither<L, C> andThen<C>(TaskEither<L, C> Function() then) => throw '';
  TaskEither<L, R> chainFirst<C>(TaskEither<L, C> Function(R b) chain) =>
      throw '';
  TaskEither<L, R> filterOrElse(
    bool Function(R r) f,
    L Function(R r) onFalse,
  ) => throw '';
  static TaskEither<E, List<A>> sequenceList<E, A>(
    List<TaskEither<E, A>> list,
  ) => throw '';
  static TaskEither<E, List<A>> sequenceListSeq<E, A>(
    List<TaskEither<E, A>> list,
  ) => throw '';
  TaskEither<L, B> chainEither<B>(Either<L, B> Function(R r) f) => throw '';
  TaskEither<L, R> alt(TaskEither<L, R> Function() orElse) => throw '';
  TaskEither<L, R> orElse<C>(TaskEither<L, R> Function(L l) onLeft) => throw '';
  Task<R> getOrElse(R Function(L l) orElse) => throw '';
  Task<B> match<B>(B Function(L l) onLeft, B Function(R r) onRight) => throw '';
  Future<Either<L, R>> run() => _run();
}
''',

  'lib/src/task_option.dart': r'''

import 'option.dart';

final class TaskOption<R> {
  final Future<Option<R>> Function() _run;
  const TaskOption(this._run);
  factory TaskOption.of(R r) => throw '';
  TaskOption<B> map<B>(B Function(R r) f) => throw '';
  TaskOption<B> flatMap<B>(TaskOption<B> Function(R r) f) => throw '';
  Future<Option<R>> run() => _run();
}
''',

  'lib/src/io.dart': r'''

final class IO<A> {
  final A Function() _run;
  const IO(this._run);
  factory IO.of(A a) => throw '';
  IO<B> map<B>(B Function(A a) f) => throw '';
  IO<B> flatMap<B>(IO<B> Function(A a) f) => throw '';
  A run() => _run();
}
''',

  'lib/src/io_either.dart': r'''

import 'either.dart';

final class IOEither<L, R> {
  final Either<L, R> Function() _run;
  const IOEither(this._run);
  factory IOEither.of(R r) => throw '';
  IOEither<L, B> map<B>(B Function(R r) f) => throw '';
  IOEither<L, B> flatMap<B>(IOEither<L, B> Function(R r) f) => throw '';
  Either<L, R> run() => _run();
}
''',

  'lib/src/io_option.dart': r'''

import 'option.dart';

final class IOOption<R> {
  final Option<R> Function() _run;
  const IOOption(this._run);
  factory IOOption.of(R r) => throw '';
  IOOption<B> map<B>(B Function(R r) f) => throw '';
  Option<R> run() => _run();
}
''',

  'lib/src/extension/iterable_extension.dart': r'''

import '../option.dart';

extension FpdartOnIterable<T> on Iterable<T> {
  Option<T> get head => throw '';
  Option<T> get firstOption => throw '';
  Option<T> get lastOption => throw '';
  Option<T> get singleOption => throw '';
  Option<T> elementAtOption(int index) => throw '';
  Option<T> singleWhereOption(bool Function(T) test) => throw '';
  Option<T> lastWhereOption(bool Function(T) test) => throw '';
}
''',

  'lib/src/extension/map_extension.dart': r'''

import '../option.dart';

extension FpdartOnMap<K, V> on Map<K, V> {
  Option<V> lookup(K key) => throw '';
  Map<K, V> mapValue(V Function(V value) f) => throw '';
}
''',

  'lib/src/extension/string_extension.dart': r'''

import '../either.dart';
import '../option.dart';

extension FpdartOnString on String {
  Option<int> get toIntOption => throw '';
  Option<double> get toDoubleOption => throw '';
  Option<num> get toNumOption => throw '';
  Option<bool> get toBoolOption => throw '';
  Either<L, int> toIntEither<L>(L Function() onError) => throw '';
  Either<L, double> toDoubleEither<L>(L Function() onError) => throw '';
  Either<L, num> toNumEither<L>(L Function() onError) => throw '';
  Either<L, bool> toBoolEither<L>(L Function() onError) => throw '';
}
''',

  'lib/fpdart.dart': r'''

export 'src/either.dart';
export 'src/extension/iterable_extension.dart';
export 'src/extension/map_extension.dart';
export 'src/extension/string_extension.dart';
export 'src/io.dart';
export 'src/io_either.dart';
export 'src/io_option.dart';
export 'src/option.dart';
export 'src/task.dart';
export 'src/task_either.dart';
export 'src/task_option.dart';
export 'src/unit.dart';
''',
};
