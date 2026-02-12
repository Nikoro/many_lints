import 'package:flutter/material.dart';

// prefer_shorthands_with_constructors
//
// Suggests using dot shorthand constructor invocations instead of
// explicit class instantiations when the type can be inferred from context.
//
// Supported classes: EdgeInsets, BorderRadius, Radius, Border
//
// NOTE: To extend this rule to support additional classes, you would need to
// modify the _defaultClasses set in the rule implementation.
// Future versions may support configuration via analysis_options.yaml.

class PreferShorthandsWithConstructorsExample extends StatelessWidget {
  const PreferShorthandsWithConstructorsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // === EdgeInsets examples ===

        // LINT: Use .symmetric instead of EdgeInsets.symmetric
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Text('Hello')),

        // LINT: Use .all instead of EdgeInsets.all
        Padding(padding: EdgeInsets.all(8), child: Text('World')),

        // LINT: Use .only instead of EdgeInsets.only
        Container(margin: EdgeInsets.only(top: 10, left: 20), child: Text('With margin')),

        // === BorderRadius and Border examples ===

        // LINT: Use .circular instead of BorderRadius.circular
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            // LINT: Use .all instead of Border.all
            border: Border.all(color: Colors.blue, width: 2),
          ),
        ),

        // LINT: Multiple shorthands in one widget
        Container(
          decoration: BoxDecoration(
            // LINT: Use .all instead of BorderRadius.all
            borderRadius: BorderRadius.all(Radius.circular(12)),
            // LINT: Use .circular instead of Radius.circular
            border: Border.all(color: Colors.red),
          ),
        ),

        // === Good examples (already using shorthand) ===
        Padding(padding: .symmetric(horizontal: 16, vertical: 12), child: Text('Good: Using dot shorthand')),

        Container(
          decoration: BoxDecoration(
            borderRadius: .circular(8),
            border: .all(color: Colors.green, width: 1),
          ),
        ),

        // === In collections ===

        // LINT: Works in list literals too
        ...[
          Padding(padding: EdgeInsets.all(4), child: Text('Item 1')),
          Padding(padding: EdgeInsets.all(4), child: Text('Item 2')),
        ],
      ],
    );
  }

  // Example showing why this is useful:
  Widget _buildCard({required Widget child, required EdgeInsets padding, required BorderRadius borderRadius}) {
    return Container(
      // GOOD: Type is already declared in parameter
      padding: .all(16), // Instead of EdgeInsets.all(16)
      decoration: BoxDecoration(
        borderRadius: .circular(12), // Instead of BorderRadius.circular(12)
      ),
      child: child,
    );
  }
}
