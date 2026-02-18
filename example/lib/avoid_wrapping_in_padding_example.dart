import 'package:flutter/material.dart';

// avoid_wrapping_in_padding
//
// Avoid wrapping widgets that support a `padding` parameter in a Padding
// widget. Use the child widget's own padding parameter instead.

class AvoidWrappingInPaddingExample extends StatelessWidget {
  const AvoidWrappingInPaddingExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Container supports padding, no need to wrap in Padding
        Padding(
          padding: EdgeInsets.all(16),
          child: Container(child: Text('Hello')),
        ),

        // LINT: Container with no arguments, still supports padding
        Padding(padding: EdgeInsets.all(8), child: Container()),

        // LINT: Card supports padding
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Card(child: Text('Card content')),
        ),
      ],
    );
  }
}

// Good: Use the child widget's padding parameter directly
class GoodExamples extends StatelessWidget {
  const GoodExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Good: padding passed directly to Container
        Container(padding: EdgeInsets.all(16), child: Text('Hello')),

        // Good: Padding wrapping a widget that doesn't support padding
        Padding(padding: EdgeInsets.all(8), child: Text('Hello')),

        // Good: Padding wrapping an Icon (no padding parameter)
        Padding(padding: EdgeInsets.all(8), child: Icon(Icons.star)),

        // Good: Container already has its own padding set
        Padding(
          padding: EdgeInsets.all(8),
          child: Container(padding: EdgeInsets.all(4), child: Text('Hello')),
        ),
      ],
    );
  }
}
