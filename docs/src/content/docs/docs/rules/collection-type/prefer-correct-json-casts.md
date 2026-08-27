---
title: prefer_correct_json_casts
description: "Cast JSON values to nullable types"
sidebar:
  label: prefer_correct_json_casts
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection &amp; Type</span>

Flags a value indexed out of a `Map<String, dynamic>` and cast to a non-nullable type. A missing key yields `null`, and casting `null` to a non-nullable type throws.

## Don't

`jsonDecode` returns `Map<String, dynamic>`, where an absent key is `null` rather than an error. The cast turns a benign missing field into a `TypeError`:

```dart
class User {
  User.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      email = json['email'] as String;

  final String name;
  final String email;
}
```

The message names only the types — "type 'Null' is not a subtype of type 'String'" — never the key. In a model with twenty fields, that leaves nothing to go on.

## Do

Cast to the nullable type and say what an absent field means:

```dart
class User {
  User.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String? ?? '',
      email = json['email'] as String? ?? '';

  final String name;
  final String email;
}
```

### When the field really is required

A nullable cast is not an invitation to paper over a broken payload. When absence is a genuine error, make it one that names the key:

```dart
class User {
  User.fromJson(Map<String, dynamic> json)
    : name = _required(json, 'name'),
      email = _required(json, 'email');

  final String name;
  final String email;

  static String _required(Map<String, dynamic> json, String key) {
    final value = json[key] as String?;
    if (value == null) throw FormatException('Missing field: $key');
    return value;
  }
}
```

## Known limitations

**Only index reads on a `dynamic`-valued map are checked.** A `Map<String, String>` cannot silently produce `null` for a present key, and a non-index expression such as `json.length` cannot be absent.

**Casts to `dynamic` and `Object` are not reported**, since both accept `null`.

**A nested read is not reported.** In `json['user']['name'] as String` the inner index yields `dynamic`, not a `Map`, so the outer cast has no map-typed receiver to check. Cast each level as you go — `(json['user'] as Map<String, dynamic>?)?['name'] as String?` — and both steps are visible.

**See also:** [dart:convert jsonDecode](https://api.dart.dev/stable/dart-convert/jsonDecode.html)

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

## Related rules

- [`avoid_not_encodable_in_to_json`](/many_lints/docs/rules/collection-type/avoid-not-encodable-in-to-json/) — Don't put values jsonEncode cannot serialize into a toJson map.
- [`avoid_unrelated_type_casts`](/many_lints/docs/rules/collection-type/avoid-unrelated-type-casts/) — Don't cast or type-test between unrelated types.
- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
