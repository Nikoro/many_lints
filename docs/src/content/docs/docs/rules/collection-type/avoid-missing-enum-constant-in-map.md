---
title: avoid_missing_enum_constant_in_map
description: "Cover every enum constant in a map keyed by that enum"
sidebar:
  label: avoid_missing_enum_constant_in_map
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection Type</span>

This rule flags a map literal whose key type is an enum but whose entries do not cover every constant of that enum.

## Why use this rule

A map keyed by an enum is almost always intended as a total lookup table — labels, icons, colors, route names. When a constant is missing, `map[value]` returns `null` rather than failing, so the gap travels: it becomes a null-check crash, an empty label, or a `!` that throws somewhere unrelated.

The bigger risk is drift. A `switch` over an enum is checked for exhaustiveness by the compiler, so adding a constant produces errors at every site that must change. A map gets no such check — add a constant and every lookup table in the codebase is quietly incomplete.

**See also:** [Dart enums](https://dart.dev/language/enums)

## Don't

```dart
enum Status { active, inactive, pending }

const statusLabels = <Status, String>{
  Status.active: 'Active',
  Status.inactive: 'Inactive',
  // pending is missing — lookups return null
};
```

## Do

```dart
enum Status { active, inactive, pending }

const statusLabels = <Status, String>{
  Status.active: 'Active',
  Status.inactive: 'Inactive',
  Status.pending: 'Pending',
};
```

When a total map is not what you want, make the fallback explicit at the lookup instead:

```dart
final label = statusLabels[status] ?? 'Unknown';
```

## Known limitations

The rule only reports when the map's contents can be enumerated statically. It stays silent when the literal contains a spread (`...other`), an `if` or `for` element, or a key that is not a plain enum constant reference — in those cases the final key set is not knowable at analysis time.

An empty map literal is also skipped, since that is a deliberate starting point rather than an oversight.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_missing_enum_constant_in_map: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_missing_enum_constant_in_map: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
