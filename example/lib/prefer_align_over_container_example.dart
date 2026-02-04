import 'package:flutter/material.dart';

// prefer_align_over_container
//
// Use Align widget instead of Container when only alignment is set.

class PreferAlignOverContainerExample extends StatelessWidget {
  const PreferAlignOverContainerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Container with only alignment parameter
        Container(alignment: Alignment.topLeft, child: Text('Hello')),

        // LINT: Container with only alignment, no child
        Container(alignment: Alignment.bottomRight),
      ],
    );
  }
}
