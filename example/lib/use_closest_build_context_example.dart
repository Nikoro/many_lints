import 'package:flutter/material.dart';

// use_closest_build_context
//
// Warns when an outer BuildContext is used inside a nested builder callback
// that provides its own BuildContext. Using the wrong context can lead to
// hard-to-spot bugs, especially when the inner parameter was renamed to `_`
// because it was previously unused.

// ❌ Bad: Uses the outer `context` instead of the Builder's own context
class BadExample extends StatelessWidget {
  const BadExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (_) {
        // LINT: Uses outer `context` when the Builder provides its own
        return _buildMyWidget(context);
      },
    );
  }

  Widget _buildMyWidget(BuildContext ctx) => const Text('hello');
}

// ❌ Bad: Same issue with LayoutBuilder
class BadLayoutBuilderExample extends StatelessWidget {
  const BadLayoutBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        // LINT: Uses outer `context` when LayoutBuilder provides its own
        return SizedBox(
          width: constraints.maxWidth,
          child: _buildMyWidget(context),
        );
      },
    );
  }

  Widget _buildMyWidget(BuildContext ctx) => const Text('hello');
}

// ✅ Good: Uses the Builder's own context
class GoodExample extends StatelessWidget {
  const GoodExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return _buildMyWidget(context);
      },
    );
  }

  Widget _buildMyWidget(BuildContext ctx) => const Text('hello');
}

// ✅ Good: Inner context has a different name but is actually used
class GoodNamedContextExample extends StatelessWidget {
  const GoodNamedContextExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (innerContext) {
        return _buildMyWidget(innerContext);
      },
    );
  }

  Widget _buildMyWidget(BuildContext ctx) => const Text('hello');
}

// ✅ Good: No nested builder — using context directly is fine
class GoodNoBuilderExample extends StatelessWidget {
  const GoodNoBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildMyWidget(context);
  }

  Widget _buildMyWidget(BuildContext ctx) => const Text('hello');
}
