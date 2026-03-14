---
title: prefer_padding_over_container
description: "Use Padding widget instead of the Container widget with only the padding or margin parameter"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_padding_over_container
---

| Property | Value |
|----------|-------|
| **Rule name** | `prefer_padding_over_container` |
| **Category** | Widget Replacement |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use Padding widget instead of the Container widget with only the padding or margin parameter

## Suggestion

Try using Padding instead of Container.

## Example

```dart
import 'package:flutter/material.dart';

// prefer_padding_over_container
//
// Use Padding widget instead of Container when only padding or margin is set.

class PreferPaddingOverContainerExample extends StatelessWidget {
  const PreferPaddingOverContainerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Container with only margin parameter
        Container(margin: EdgeInsets.all(16), child: Text('Hello')),

        // LINT: Container with only margin, no child
        Container(margin: EdgeInsets.symmetric(horizontal: 8)),

        // LINT: Container with only padding parameter
        Container(padding: EdgeInsets.all(16), child: Text('Hello')),

        // LINT: Container with only padding, no child
        Container(padding: EdgeInsets.symmetric(vertical: 8)),
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
      prefer_padding_over_container: false
```
