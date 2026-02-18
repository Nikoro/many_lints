import 'package:flutter/material.dart';

// prefer_container
//
// Warns when a sequence of 3+ nested widgets can be replaced with a single
// Container widget.

// ❌ Bad: Nesting multiple Container-compatible widgets
class BadExamples extends StatelessWidget {
  const BadExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Transform > Padding > Align can be replaced with Container
        Transform(
          transform: Matrix4.identity(),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Align(alignment: Alignment.center, child: Text('Hello')),
          ),
        ),

        // LINT: Padding > ColoredBox > SizedBox can be replaced with Container
        Padding(
          padding: EdgeInsets.all(8),
          child: ColoredBox(
            color: Colors.red,
            child: SizedBox(width: 100, height: 50, child: Text('World')),
          ),
        ),
      ],
    );
  }
}

// ✅ Good: Using Container instead of nesting
class GoodExamples extends StatelessWidget {
  const GoodExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Good: Single Container combines all properties
        Container(
          transform: Matrix4.identity(),
          padding: EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Text('Hello'),
        ),

        // Good: Single Container with color and size
        Container(
          padding: EdgeInsets.all(8),
          color: Colors.red,
          width: 100,
          height: 50,
          child: Text('World'),
        ),

        // Good: Only 2 nested widgets (below threshold)
        Padding(
          padding: EdgeInsets.all(8),
          child: Align(alignment: Alignment.center, child: Text('OK')),
        ),
      ],
    );
  }
}
