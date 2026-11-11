// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_private_named_parameters, many_lints/prefer_primary_constructors
// ignore_for_file: many_lints/prefer_returning_shorthands

import 'banned_usage_clock.dart';

// banned_usage
//
// Warns when a banned member is used — one member of a type, rather than the
// whole type. The rule reports nothing until you configure it — see the
// `banned_usage` entry in example/many_lints.yaml, which bans 'DateTime.now'
// in this file to stand in for a domain layer that must stay testable.

/// A seam the domain layer can control in a test.
abstract class Clock {
  DateTime now();
}

class BadSession {
  const BadSession(this.expiresAt);

  final DateTime expiresAt;

  // LINT: 'DateTime.now' is banned here — this cannot be tested at a chosen
  // moment without waiting for real time to pass.
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class BadStopwatch {
  // LINT: a tear-off hands out the same hidden input as a call.
  BadStopwatch({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  DateTime lap() => _now();
}

// LINT: a dot shorthand is the same constructor under a shorter name.
DateTime badStartedAt() => .now();

// ✅ Good: take the clock as a dependency, so a test can decide "now".
class Session {
  const Session({required this.expiresAt, required Clock clock})
    : _clock = clock;

  final DateTime expiresAt;
  final Clock _clock;

  bool get isExpired => _clock.now().isAfter(expiresAt);
}

// OK: only the banned member is reported, not the whole type — DateTime
// itself stays perfectly usable.
DateTime parseStamp(String raw) => DateTime.parse(raw);

// 🔹 Edge case: 'Type.member' matches on the type that *declares* the member,
// so a subclass cannot slip past — banning 'Iterable.first' also catches a
// List receiver. The unnamed constructor is written 'new', so 'Random.new'
// bans `Random()` while leaving `Random.secure()` alone.

// LINT: 'systemClock' is banned everywhere under lib/ except the file that
// declares it. The entry names it with its library,
// 'package:example/banned_usage_clock.dart#systemClock', so a member or a
// declaration elsewhere that happens to share the name stays allowed.
DateTime badReadsTheGlobalClock() => systemClock();

// OK: a different declaration with the same name is not the banned one.
abstract final class Fixture {
  static DateTime systemClock() => DateTime.utc(2026);
}

DateTime fixtureNow() => Fixture.systemClock();
