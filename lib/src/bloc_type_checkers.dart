import './type_checker.dart';

const blocChecker = TypeChecker.fromName('Bloc', packageName: 'bloc');

const cubitChecker = TypeChecker.fromName('Cubit', packageName: 'bloc');

const blocBaseChecker = TypeChecker.fromName('BlocBase', packageName: 'bloc');

const blocOrCubitChecker = TypeChecker.any([blocChecker, cubitChecker]);

const blocProviderChecker = TypeChecker.fromName(
  'BlocProvider',
  packageName: 'flutter_bloc',
);

const blocListenerChecker = TypeChecker.fromName(
  'BlocListener',
  packageName: 'flutter_bloc',
);

const repositoryProviderChecker = TypeChecker.fromName(
  'RepositoryProvider',
  packageName: 'flutter_bloc',
);
