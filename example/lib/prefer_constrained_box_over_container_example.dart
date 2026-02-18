import 'package:flutter/material.dart';

// prefer_constrained_box_over_container
//
// Use ConstrainedBox widget instead of Container when only constraints is set.

// ignore_for_file: unused_local_variable

class PreferConstrainedBoxOverContainerExample extends StatelessWidget {
  const PreferConstrainedBoxOverContainerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ❌ Bad: Container with only constraints parameter
        // LINT: Use ConstrainedBox instead of Container with only constraints
        Container(
          constraints: BoxConstraints(maxWidth: 200),
          child: Text('Hello'),
        ),

        // LINT: Container with only constraints, no child
        Container(constraints: BoxConstraints.tightFor(width: 100)),

        // ✅ Good: Use ConstrainedBox directly
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 200),
          child: Text('Hello'),
        ),

        // ✅ Good: Container with additional properties besides constraints
        Container(
          constraints: BoxConstraints(maxWidth: 200),
          padding: EdgeInsets.all(8),
          child: Text('Hello'),
        ),
      ],
    );
  }
}
