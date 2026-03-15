---
title: prefer_text_rich
description: "Use Text.rich instead of RichText for better accessibility"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_text_rich
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags usages of `RichText` which should be replaced with `Text.rich`. `RichText` does not respect `MediaQuery` text scaling by default, which can break accessibility for users who configure larger text sizes.

## Why use this rule

`Text.rich` inherits the default `TextStyle` from the nearest `DefaultTextStyle` ancestor and automatically applies text scaling from `MediaQuery`. `RichText` does neither -- it requires you to pass these explicitly. Using `Text.rich` gives you correct accessibility behavior out of the box and is the recommended approach for rich text in Flutter.

**See also:** [Text.rich](https://api.flutter.dev/flutter/widgets/Text/Text.rich.html) | [RichText](https://api.flutter.dev/flutter/widgets/RichText-class.html)

## Don't

```dart
// RichText does not handle text scaling
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
);

// Even simple RichText should use Text.rich
RichText(text: TextSpan(text: 'Simple text'));
```

## Do

```dart
// Text.rich handles text scaling and inherits default style
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
);

Text.rich(TextSpan(text: 'Simple text'));
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_text_rich: false
```
