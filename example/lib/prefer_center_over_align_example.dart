import 'package:flutter/material.dart';

// prefer_center_over_align
//
// Use Center widget instead of Align when alignment is center.

class PreferCenterOverAlignExample extends StatelessWidget {
  const PreferCenterOverAlignExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Align with Alignment.center should be Center
        Align(alignment: Alignment.center, child: Text('Hello')),

        // LINT: Align without alignment defaults to center
        Align(child: Text('World')),
      ],
    );
  }
}
