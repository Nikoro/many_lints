// ignore_for_file: unused_local_variable

// prefer_correct_edge_insets_constructor
//
// Warns when an EdgeInsets constructor can be replaced with a simpler one.

import 'package:flutter/painting.dart';

// ❌ Bad: EdgeInsets.fromLTRB with all equal values
class BadFromLTRBAllEqual {
  void example() {
    // LINT: Use EdgeInsets.all(8) instead
    final p = EdgeInsets.fromLTRB(8, 8, 8, 8);
  }
}

// ❌ Bad: EdgeInsets.fromLTRB with symmetric values
class BadFromLTRBSymmetric {
  void example() {
    // LINT: Use EdgeInsets.symmetric(horizontal: 8) instead
    final p = EdgeInsets.fromLTRB(8, 0, 8, 0);

    // LINT: Use EdgeInsets.symmetric(horizontal: 8, vertical: 4) instead
    final p2 = EdgeInsets.fromLTRB(8, 4, 8, 4);
  }
}

// ❌ Bad: EdgeInsets.fromLTRB with some zero values
class BadFromLTRBOnly {
  void example() {
    // LINT: Use EdgeInsets.only(left: 8) instead
    final p = EdgeInsets.fromLTRB(8, 0, 0, 0);
  }
}

// ❌ Bad: EdgeInsets.only with symmetric values
class BadOnlySymmetric {
  void example() {
    // LINT: Use EdgeInsets.symmetric(horizontal: 16) instead
    final p = EdgeInsets.only(left: 16, right: 16);
  }
}

// ❌ Bad: EdgeInsets.only with all equal values
class BadOnlyAllEqual {
  void example() {
    // LINT: Use EdgeInsets.all(8) instead
    final p = EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 8);
  }
}

// ❌ Bad: EdgeInsets.symmetric with both values equal
class BadSymmetricEqual {
  void example() {
    // LINT: Use EdgeInsets.all(8) instead
    final p = EdgeInsets.symmetric(horizontal: 8, vertical: 8);
  }
}

// ❌ Bad: EdgeInsets.all(0) should be EdgeInsets.zero
class BadAllZero {
  void example() {
    // LINT: Use EdgeInsets.zero instead
    final p = EdgeInsets.all(0);
  }
}

// ❌ Bad: EdgeInsets.fromLTRB(0, 0, 0, 0) should be EdgeInsets.zero
class BadFromLTRBZero {
  void example() {
    // LINT: Use EdgeInsets.zero instead
    final p = EdgeInsets.fromLTRB(0, 0, 0, 0);
  }
}

// ✅ Good: Using the correct constructor
class GoodExamples {
  void example() {
    final p1 = EdgeInsets.all(8);
    final p2 = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    final p3 = EdgeInsets.symmetric(horizontal: 16);
    final p4 = EdgeInsets.only(left: 8);
    final p5 = EdgeInsets.only(left: 8, top: 4);
    final p6 = EdgeInsets.zero;
    final p7 = EdgeInsets.fromLTRB(1, 2, 3, 4);
  }
}
