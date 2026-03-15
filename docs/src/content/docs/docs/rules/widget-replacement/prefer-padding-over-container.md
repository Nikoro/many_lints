---
title: prefer_padding_over_container
description: "Use Padding instead of Container when only padding or margin is set"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_padding_over_container
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `Container` widgets that only use the `padding` or `margin` parameter (plus optional `key` and `child`). When `Container` is used solely for spacing, the `Padding` widget is a lighter, more descriptive alternative.

## Why use this rule

`Container` is a convenience widget that composes many lower-level widgets internally. When you only need padding or margin, using `Padding` directly avoids the overhead and makes the intent immediately clear. This also keeps the widget tree shallow and easier to read during debugging.

**See also:** [Padding](https://api.flutter.dev/flutter/widgets/Padding-class.html) | [Container](https://api.flutter.dev/flutter/widgets/Container-class.html)

## Don't

```dart
// Container with only margin parameter
Container(margin: EdgeInsets.all(16), child: Text('Hello'));

// Container with only margin, no child
Container(margin: EdgeInsets.symmetric(horizontal: 8));

// Container with only padding parameter
Container(padding: EdgeInsets.all(16), child: Text('Hello'));

// Container with only padding, no child
Container(padding: EdgeInsets.symmetric(vertical: 8));
```

## Do

```dart
// Use Padding directly
Padding(padding: EdgeInsets.all(16), child: Text('Hello'));

Padding(padding: EdgeInsets.symmetric(horizontal: 8));

Padding(padding: EdgeInsets.all(16), child: Text('Hello'));

Padding(padding: EdgeInsets.symmetric(vertical: 8));
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_padding_over_container: false
```
