// Support file for banned_usage_example.dart.
//
// Stands in for the composition root that owns the system clock. The
// `banned_usage` entry in example/many_lints.yaml bans `systemClock` in every
// file under lib/ and names this one under `except:`, so it may read it.

/// The process-wide clock source, read only where the app is wired together.
final DateTime Function() systemClock = DateTime.now;

/// Reading the clock here is allowed: this file is the entry's exception.
DateTime wiredNow() => systemClock();
