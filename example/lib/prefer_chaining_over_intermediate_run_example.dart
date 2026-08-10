// ignore_for_file: unused_element, unused_local_variable

// prefer_chaining_over_intermediate_run
//
// `flatMap` carries the error channel through the whole pipeline: a failing
// step short-circuits the rest and the handling is written once. Running each
// step separately rebuilds all of that by hand — and is where failures get
// quietly lost.

import 'package:fpdart/fpdart.dart';

class _Area {
  const _Area(this.id);
  final int id;
}

class _Deal {
  const _Deal(this.price);
  final double price;
}

TaskEither<String, _Area> _getArea() => TaskEither.of(const _Area(1));

TaskEither<String, _Deal> _getDeal(int areaId) =>
    TaskEither.of(const _Deal(9.99));

// ❌ Bad: two pipelines run separately, unwrapped by hand
// LINT: chain with flatMap and run once
Future<void> badSeparateRuns() async {
  final area = await _getArea().run();
  final deal = await _getDeal(1).run();
}

// ✅ Good: one chain, one run, failures propagate untouched
TaskEither<String, _Deal> goodChained() =>
    _getArea().flatMap((area) => _getDeal(area.id));

// ✅ Good: a single run is the boundary the pipeline is meant to have
Future<void> goodSingleRun() async {
  final result = await goodChained().run();
}

// ✅ Good: a closure has its own boundary, so its run is not counted against
// the enclosing member
Future<void> goodRunInsideClosure() async {
  final result = await goodChained().run();
  final handler = () async => await _getArea().run();
}
