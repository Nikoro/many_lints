import './type_checker.dart';

/// TypeChecker for the `Bloc` base class — an event-driven state holder.
const blocChecker = TypeChecker.fromName('Bloc', packageName: 'bloc');

/// TypeChecker for the `Cubit` base class — a `Bloc` without events.
const cubitChecker = TypeChecker.fromName('Cubit', packageName: 'bloc');

/// TypeChecker for `BlocBase`, the shared supertype `Bloc` and `Cubit` both
/// extend.
///
/// Distinct from [blocOrCubitChecker]: this matches the declared supertype
/// itself, so it also covers a custom base that extends `BlocBase` directly
/// without going through either concrete class.
const blocBaseChecker = TypeChecker.fromName('BlocBase', packageName: 'bloc');

/// TypeChecker matching either concrete state holder, `Bloc` or `Cubit`.
///
/// Kept separate from [blocBaseChecker] even though the two nearly coincide:
/// rules that reason about `emit` and closing semantics target the two
/// concrete classes, and widening them to every `BlocBase` subtype would
/// change which declarations they visit.
const blocOrCubitChecker = TypeChecker.any([blocChecker, cubitChecker]);

/// TypeChecker for `BlocProvider`, which supplies a bloc to the widget tree.
const blocProviderChecker = TypeChecker.fromName(
  'BlocProvider',
  packageName: 'flutter_bloc',
);

/// TypeChecker for `BlocListener`, which reacts to bloc state changes.
const blocListenerChecker = TypeChecker.fromName(
  'BlocListener',
  packageName: 'flutter_bloc',
);

/// TypeChecker for `RepositoryProvider`, which supplies a repository to the
/// widget tree.
const repositoryProviderChecker = TypeChecker.fromName(
  'RepositoryProvider',
  packageName: 'flutter_bloc',
);
