import 'package:flutter/material.dart';

// use_dedicated_media_query_methods
//
// Use dedicated MediaQuery methods like MediaQuery.sizeOf(context)
// instead of MediaQuery.of(context).size to avoid unnecessary rebuilds.

class UseDedicatedMediaQueryMethodsExample extends StatelessWidget {
  const UseDedicatedMediaQueryMethodsExample({super.key});

  @override
  Widget build(BuildContext context) {
    // LINT: Use MediaQuery.sizeOf(context) instead
    final size = MediaQuery.of(context).size;

    // LINT: Use MediaQuery.paddingOf(context) instead
    final padding = MediaQuery.of(context).padding;

    // LINT: Use MediaQuery.orientationOf(context) instead
    final orientation = MediaQuery.of(context).orientation;

    return SizedBox(
      width: size.width,
      height: size.height - padding.top,
      child: Text('Orientation: $orientation'),
    );
  }
}
