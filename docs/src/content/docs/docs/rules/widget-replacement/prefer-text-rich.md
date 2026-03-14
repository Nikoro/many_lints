---
title: prefer_text_rich
description: "Use Text.rich instead of RichText for better text scaling and accessibility."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_text_rich
---

| Property | Value |
|----------|-------|
| **Rule name** | `prefer_text_rich` |
| **Category** | Widget Replacement |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use Text.rich instead of RichText for better text scaling and accessibility.

## Suggestion

Replace RichText with Text.rich.

## Example

```dart
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
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_text_rich: false
```
