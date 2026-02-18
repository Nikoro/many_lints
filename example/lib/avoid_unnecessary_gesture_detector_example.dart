import 'package:flutter/material.dart';

// avoid_unnecessary_gesture_detector
//
// Warns when a GestureDetector widget has no event handler callbacks,
// making it functionally useless.

// ignore_for_file: unused_element

// ❌ Bad: GestureDetector with no event handlers
class BadExample extends StatelessWidget {
  const BadExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: GestureDetector without any on* callback
        GestureDetector(child: Text('hello')),

        // LINT: Only non-handler arguments like behavior don't count
        GestureDetector(behavior: HitTestBehavior.opaque, child: Text('world')),
      ],
    );
  }
}

// ✅ Good: GestureDetector with event handlers
class GoodExample extends StatelessWidget {
  const GoodExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(onTap: () => print('tapped'), child: Text('hello')),

        GestureDetector(
          onLongPress: () => print('long pressed'),
          onDoubleTap: () => print('double tapped'),
          child: Text('world'),
        ),
      ],
    );
  }
}
