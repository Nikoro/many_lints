import 'package:flutter/widgets.dart';

// prefer_text_rich
//
// Warns when RichText is used instead of Text.rich.
// RichText does not handle text scaling well. Text.rich provides
// better accessibility support.

// ignore_for_file: unused_local_variable

// ❌ Bad: Using RichText directly
class BadExamples extends StatelessWidget {
  const BadExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Use Text.rich instead of RichText
        RichText(
          text: TextSpan(
            text: 'Hello ',
            children: [
              TextSpan(
                text: 'bold',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' world!'),
            ],
          ),
        ),

        // LINT: Even simple RichText should use Text.rich
        RichText(text: TextSpan(text: 'Simple text')),
      ],
    );
  }
}

// ✅ Good: Using Text.rich for better accessibility
class GoodExamples extends StatelessWidget {
  const GoodExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            text: 'Hello ',
            children: [
              TextSpan(
                text: 'bold',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' world!'),
            ],
          ),
        ),

        Text.rich(TextSpan(text: 'Simple text')),
      ],
    );
  }
}
