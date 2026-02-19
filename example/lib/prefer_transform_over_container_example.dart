import 'dart:math' as math;

import 'package:flutter/material.dart';

// prefer_transform_over_container
//
// Use Transform widget instead of Container when only transform is set.

// ❌ Bad: Container used only for transform
class BadExamples extends StatelessWidget {
  const BadExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Container with only transform parameter
        Container(
          transform: Matrix4.skewY(0.3)..rotateZ(-math.pi / 12.0),
          child: const Text('Skewed'),
        ),

        // LINT: Container with only transform and key
        Container(
          key: const ValueKey('rotated'),
          transform: Matrix4.rotationZ(math.pi / 4),
          child: const Text('Rotated'),
        ),
      ],
    );
  }
}

// ✅ Good: Using Transform widget directly
class GoodExamples extends StatelessWidget {
  const GoodExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Good: Using Transform directly
        Transform(
          transform: Matrix4.skewY(0.3)..rotateZ(-math.pi / 12.0),
          child: const Text('Skewed'),
        ),

        // Good: Container with transform and other parameters
        Container(
          transform: Matrix4.rotationZ(math.pi / 4),
          alignment: Alignment.topRight,
          child: const Text('Rotated with alignment'),
        ),
      ],
    );
  }
}
