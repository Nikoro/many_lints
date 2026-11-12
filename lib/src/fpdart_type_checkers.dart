import './type_checker.dart';

const optionChecker = TypeChecker.fromUrl(
  'package:fpdart/src/option.dart#Option',
);

const eitherChecker = TypeChecker.fromUrl(
  'package:fpdart/src/either.dart#Either',
);

const taskChecker = TypeChecker.fromUrl('package:fpdart/src/task.dart#Task');

const taskEitherChecker = TypeChecker.fromUrl(
  'package:fpdart/src/task_either.dart#TaskEither',
);

const taskOptionChecker = TypeChecker.fromUrl(
  'package:fpdart/src/task_option.dart#TaskOption',
);

const ioChecker = TypeChecker.fromUrl('package:fpdart/src/io.dart#IO');

const ioEitherChecker = TypeChecker.fromUrl(
  'package:fpdart/src/io_either.dart#IOEither',
);

const ioOptionChecker = TypeChecker.fromUrl(
  'package:fpdart/src/io_option.dart#IOOption',
);

const unitChecker = TypeChecker.fromUrl('package:fpdart/src/unit.dart#Unit');

const lazyFpdartChecker = TypeChecker.any([
  taskChecker,
  taskEitherChecker,
  taskOptionChecker,
  ioChecker,
  ioEitherChecker,
  ioOptionChecker,
]);

const failableFpdartChecker = TypeChecker.any([
  eitherChecker,
  taskEitherChecker,
  ioEitherChecker,
]);

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
