// ignore_for_file: unused_local_variable, unused_element

import 'package:flutter/material.dart';

// prefer_spacing
//
// Prefer using the `spacing` argument on Row, Column, and Flex
// instead of inserting SizedBox widgets between children.
// Requires Flutter 3.27+.

extension _ListSeparate<T> on List<T> {
  List<T> separatedBy(T separator) => [];
}

// ❌ Bad: SizedBox used as spacer between children
class BadDirectSizedBox extends StatelessWidget {
  const BadDirectSizedBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('First'),
        // LINT: Prefer passing the 'spacing' argument instead of using SizedBox
        SizedBox(height: 10),
        Text('Second'),
        // LINT: Same uniform spacing value
        SizedBox(height: 10),
        Text('Third'),
      ],
    );
  }
}

// ❌ Bad: .separatedBy() with SizedBox
class BadSeparatedBy extends StatelessWidget {
  const BadSeparatedBy({super.key});

  @override
  Widget build(BuildContext context) {
    // LINT: Prefer passing the 'spacing' argument
    return Column(
      children: [
        Text('A'),
        Text('B'),
        Text('C'),
      ].separatedBy(const SizedBox(height: 10)),
    );
  }
}

// ❌ Bad: .expand() yielding SizedBox
class BadExpand extends StatelessWidget {
  const BadExpand({super.key});

  @override
  Widget build(BuildContext context) {
    final widgets = [Text('A'), Text('B'), Text('C')];
    // LINT: Prefer passing the 'spacing' argument
    return Column(
      children: widgets
          .expand((widget) sync* {
            yield const SizedBox(height: 10);
            yield widget;
          })
          .skip(1)
          .toList(),
    );
  }
}

// ✅ Good: Using the spacing argument
class GoodSpacing extends StatelessWidget {
  const GoodSpacing({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [Text('First'), Text('Second'), Text('Third')],
    );
  }
}

// ✅ Good: Mixed spacing values (not uniform, so no lint)
class GoodMixedSpacing extends StatelessWidget {
  const GoodMixedSpacing({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('First'),
        SizedBox(height: 10),
        Text('Second'),
        SizedBox(height: 20),
        Text('Third'),
      ],
    );
  }
}

// ✅ Good: SizedBox with child (not a spacer)
class GoodSizedBoxWithChild extends StatelessWidget {
  const GoodSizedBoxWithChild({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('First'),
        SizedBox(height: 100, child: Text('Constrained')),
        Text('Second'),
      ],
    );
  }
}
