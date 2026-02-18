import 'package:flutter/material.dart';

// avoid_incorrect_image_opacity
//
// Warns when an Image widget is wrapped in an Opacity widget.
// The Image widget has a dedicated `opacity` parameter that is more efficient.

class AvoidIncorrectImageOpacityExample extends StatelessWidget {
  const AvoidIncorrectImageOpacityExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Image wrapped in Opacity — use Image's opacity parameter instead
        Opacity(opacity: 0.5, child: Image.asset('assets/logo.png')),

        // LINT: Image.network wrapped in Opacity
        Opacity(
          opacity: 0.8,
          child: Image.network('https://example.com/image.png'),
        ),
      ],
    );
  }
}

// ✅ Good: Use Image's opacity parameter directly
class GoodExample extends StatelessWidget {
  const GoodExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
          opacity: const AlwaysStoppedAnimation(0.5),
        ),
        Image.network(
          'https://example.com/image.png',
          opacity: const AlwaysStoppedAnimation(0.8),
        ),
      ],
    );
  }
}

// ✅ Good: Opacity wrapping a non-Image widget is fine
class NonImageOpacityExample extends StatelessWidget {
  const NonImageOpacityExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: 0.5, child: Text('Hello'));
  }
}
