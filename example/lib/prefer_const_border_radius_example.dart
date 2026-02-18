// ignore_for_file: unused_local_variable

// prefer_const_border_radius
//
// Prefer BorderRadius.all(Radius.circular()) over BorderRadius.circular()
// because the explicit form supports const.

import 'package:flutter/painting.dart';

// ❌ Bad: BorderRadius.circular cannot be const
class BadExamples {
  void example() {
    // LINT: BorderRadius.circular delegates to BorderRadius.all internally
    final radius = BorderRadius.circular(8);

    // LINT: Same issue with double literal
    final radius2 = BorderRadius.circular(16.0);
  }
}

// ✅ Good: BorderRadius.all(Radius.circular()) supports const
class GoodExamples {
  void example() {
    final radius = BorderRadius.all(Radius.circular(8));

    const radius2 = BorderRadius.all(Radius.circular(16.0));
  }
}
