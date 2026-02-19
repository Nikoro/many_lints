// ignore_for_file: unused_local_variable, prefer_const_constructors

// prefer_sized_box_square
//
// Warns when a SizedBox is created with identical width and height values.
// Use SizedBox.square(dimension: ...) instead for cleaner code.

import 'package:flutter/widgets.dart';

// Bad: SizedBox with equal width and height
class BadExamples {
  // LINT: Both width and height are the same literal
  Widget a() => SizedBox(width: 10, height: 10);

  // LINT: Same double literal
  Widget b() => SizedBox(width: 24.0, height: 24.0);

  // LINT: Same variable reference
  Widget c() {
    const size = 48.0;
    return SizedBox(width: size, height: size);
  }

  // LINT: With a child widget
  Widget d() => SizedBox(width: 50, height: 50, child: Text('Hello'));
}

// Good: Using SizedBox.square or different dimensions
class GoodExamples {
  // Already using SizedBox.square
  Widget a() => SizedBox.square(dimension: 10);

  // Different width and height
  Widget b() => SizedBox(width: 100, height: 50);

  // Only width specified
  Widget c() => SizedBox(width: 10);

  // Only height specified
  Widget d() => SizedBox(height: 10);

  // Using SizedBox.shrink
  Widget e() => SizedBox.shrink();

  // Using SizedBox.expand
  Widget f() => SizedBox.expand();
}
