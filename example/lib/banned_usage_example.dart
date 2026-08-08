// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_private_named_parameters
// ignore_for_file: many_lints/prefer_returning_shorthands

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
