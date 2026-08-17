---
title: prefer_correct_json_casts
description: "Cast JSON values to nullable types"
sidebar:
  label: prefer_correct_json_casts
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection &amp; Type</span>

This rule flags a value indexed out of a `Map<String, dynamic>` and cast to a non-nullable type. A missing key yields `null`, and casting `null` to a non-nullable type throws.

## Why use this rule

`jsonDecode` returns `Map<String, dynamic>`, where a missing key gives `null` rather than an error. Casting straight to `String` or `int` therefore turns a benign absent field into a `TypeError`.

The error message names only the types involved — "type 'Null' is not a subtype of type 'String'" — and never the key. In a model with twenty fields that leaves nothing to go on. Casting to the nullable type and supplying a fallback makes the absence explicit and keeps the failure where you can read it.

**See also:** [dart:convert jsonDecode](https://api.dart.dev/stable/dart-convert/jsonDecode.html)

## Don't

```dart
User.fromJson(Map<String, dynamic> json)
  : name = json['name'] as String;   // throws if 'name' is absent
```

## Do

```dart
User.fromJson(Map<String, dynamic> json)
  : name = json['name'] as String? ?? '';
```

## Known limitations

Only index reads on a map whose value type is `dynamic` are checked. A `Map<String, String>` cannot silently produce `null` for a present key, and a non-index expression such as `json.length` cannot be absent.

Casts to `dynamic` and `Object` are not reported, since both accept `null`.

## Configuration

This rule is in the **`opinionated`** preset. With a lower preset, enable it by
name with `prefer_correct_json_casts: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_correct_json_casts: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
