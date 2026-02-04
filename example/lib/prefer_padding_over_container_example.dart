import 'package:flutter/material.dart';

// prefer_padding_over_container
//
// Use Padding widget instead of Container when only margin is set.

class PreferPaddingOverContainerExample extends StatelessWidget {
  const PreferPaddingOverContainerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Container with only margin parameter
        Container(margin: EdgeInsets.all(16), child: Text('Hello')),

        // LINT: Container with only margin, no child
        Container(margin: EdgeInsets.symmetric(horizontal: 8)),
      ],
    );
  }
}
