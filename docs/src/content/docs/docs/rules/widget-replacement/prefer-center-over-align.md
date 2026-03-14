---
title: prefer_center_over_align
description: "Use the Center widget instead of the Align widget with alignment set to Alignment.center"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_center_over_align
---

| Property | Value |
|----------|-------|
| **Rule name** | `prefer_center_over_align` |
| **Category** | Widget Replacement |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use the Center widget instead of the Align widget with alignment set to Alignment.center

## Suggestion

Try using Center instead of Align.

## Example

```dart
import 'package:flutter/material.dart';

// prefer_center_over_align
//
// Use Center widget instead of Align when alignment is center.

class PreferCenterOverAlignExample extends StatelessWidget {
  const PreferCenterOverAlignExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Align with Alignment.center should be Center
        Align(alignment: Alignment.center, child: Text('Hello')),

        // LINT: Align without alignment defaults to center
        Align(child: Text('World')),
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
      prefer_center_over_align: false
```
