// ignore_for_file: unused_local_variable
// ignore_for_file: many_lints/prefer_shorthands_with_enums

// avoid_border_all
//
// Prefer Border.fromBorderSide over Border.all for const support.
// Border.all() calls Border.fromBorderSide() under the hood, so using
// Border.fromBorderSide(BorderSide(...)) directly allows the expression
// to be const.

import 'package:flutter/painting.dart';

// ❌ Bad: Using Border.all()
void bad() {
  // LINT: Border.all() can be replaced with Border.fromBorderSide()
  final border1 = Border.all();

  // LINT: Border.all() with arguments
  final border2 = Border.all(
    color: const Color(0xFF3355AA),
    width: 2.5,
    style: BorderStyle.solid,
  );
}

// ✅ Good: Using Border.fromBorderSide() directly
void good() {
  final border1 = const Border.fromBorderSide(BorderSide());

  final border2 = const Border.fromBorderSide(
    BorderSide(color: Color(0xFF3355AA), width: 2.5, style: BorderStyle.solid),
  );
}
