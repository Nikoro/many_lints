---
title: avoid_not_encodable_in_to_json
description: "Don't put values jsonEncode cannot serialize into a toJson map"
sidebar:
  label: avoid_not_encodable_in_to_json
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection &amp; Type</span>

This rule flags a value in a `toJson` map that `jsonEncode` cannot serialize — a `DateTime`, an enum, or a nested model with no `toJson` of its own.

## Why use this rule

`jsonEncode` accepts only `num`, `String`, `bool`, `null`, `List` and `Map`. Anything else throws `JsonUnsupportedObjectError`.

The type system does not help here, because `Map<String, dynamic>` accepts every value. The mistake compiles cleanly and only fails when the map is actually encoded — often in a different layer, on a code path that tests do not cover. What should have been a type error becomes a production stack trace.

**See also:** [dart:convert jsonEncode](https://api.dart.dev/stable/dart-convert/jsonEncode.html), [JsonUnsupportedObjectError](https://api.dart.dev/stable/dart-convert/JsonUnsupportedObjectError-class.html)

## Don't

```dart
class Event {
  final DateTime createdAt;
  final Status status;

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt,   // throws at encode time
    'status': status,         // enums are not encodable either
  };
}
```

## Do

Convert each value to something `jsonEncode` understands:

```dart
Map<String, dynamic> toJson() => {
  'createdAt': createdAt.toIso8601String(),
  'status': status.name,
};
```

A nested model is fine as long as it declares its own `toJson` — `jsonEncode` reaches it through the `toEncodable` hook:

```dart
class Address {
  Map<String, dynamic> toJson() => {'city': city};
}

Map<String, dynamic> toJson() => {'address': address};   // accepted
```

## Known limitations

Collections are checked through their type arguments, so `List<DateTime>` is reported while `List<String>` is not. A `Map`'s values are checked; its keys are not, since `jsonEncode` stringifies them.

`dynamic` and `Object` values are never reported — the runtime value may well be encodable, so any report would be guesswork. Type parameters are skipped for the same reason.

Only map literals returned directly from `toJson` are inspected. A map built up statement by statement, or returned from a helper, is not analysed.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_not_encodable_in_to_json: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  avoid_not_encodable_in_to_json:
    allowed_types: [Decimal, Uint8List]
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `allowed_types` | list of strings | `[]` | Type names to treat as encodable, for projects whose serializer handles them through a custom converter |

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
