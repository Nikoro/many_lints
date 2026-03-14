---
title: use_dedicated_media_query_methods
description: "Avoid using {0} to access only one property of MediaQueryData. Using aspects of the MediaQuery avoids unnecessary rebuilds."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_dedicated_media_query_methods
---

| Property | Value |
|----------|-------|
| **Rule name** | `use_dedicated_media_query_methods` |
| **Category** | Widget Best Practices |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Avoid using {0} to access only one property of MediaQueryData. Using aspects of the MediaQuery avoids unnecessary rebuilds.

## Suggestion

Use the dedicated `{1}` method instead.

## Example

```dart
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
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_dedicated_media_query_methods: false
```
