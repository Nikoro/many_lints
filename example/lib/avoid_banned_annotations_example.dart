// ignore_for_file: unused_element

import 'package:meta/meta.dart';

// avoid_banned_annotations
//
// Warns when a banned annotation is used in a file. The rule reports nothing
// until you configure it — see the `avoid_banned_annotations` entry in
// example/many_lints.yaml, which bans '@visibleForTesting' in this file to
// stand in for a production directory where encapsulation must hold.

/// A seam the test can control without opening the type.
abstract class Ledger {
  void reset();
}

class BadPaymentService {
  // LINT: '@visibleForTesting' widens visibility so a test can reach in.
  @visibleForTesting
  void resetLedger() {}
}

// ✅ Good: inject what the test needs to control, and keep the type closed.
class PaymentService {
  const PaymentService(this._ledger);

  final Ledger _ledger;

  void refundAll() => _ledger.reset();
}

// OK: other annotations are untouched — only names an entry lists are banned.
@immutable
class Config {
  const Config(this.retries);

  final int retries;
}

// 🔹 Edge case: configure the bare name, without the '@'. Both
// '@visibleForTesting' and a prefixed '@meta.visibleForTesting' match the same
// entry, so an import prefix cannot slip past the rule.
// ignore_for_file: many_lints/prefer_primary_constructors
