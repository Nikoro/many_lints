---
title: prefer_align_over_container
description: "Use Align widget instead of the Container widget with only the alignment parameter"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_align_over_container
---

| Property | Value |
|----------|-------|
| **Rule name** | `prefer_align_over_container` |
| **Category** | Widget Replacement |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use Align widget instead of the Container widget with only the alignment parameter

## Suggestion

Try using Align instead of Container.

## Example

```dart
import 'package:flutter/material.dart';

// prefer_align_over_container
//
// Use Align widget instead of Container when only alignment is set.

class PreferAlignOverContainerExample extends StatelessWidget {
  const PreferAlignOverContainerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Container with only alignment parameter
        Container(alignment: Alignment.topLeft, child: Text('Hello')),

        // LINT: Container with only alignment, no child
        Container(alignment: Alignment.bottomRight),
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
      prefer_align_over_container: false
```
