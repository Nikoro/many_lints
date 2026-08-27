---
title: list_all_equatable_fields
description: "Ensure all fields are listed in Equatable props."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: list_all_equatable_fields
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Flags a class extending `Equatable` or mixing in `EquatableMixin` whose `props` getter omits one of its own instance fields. The diagnostic names the missing fields, and the quick fix adds them.

## Don't

A field added after the fact, with `props` left as it was. The class still compiles, and two objects that differ only in `unreadCount` now compare equal:

```dart
import 'package:equatable/equatable.dart';

class InboxState extends Equatable {
  const InboxState(this.messages, this.unreadCount);

  final List<String> messages;
  final int unreadCount;

  @override
  List<Object?> get props => [messages];
}
```

This is worse than a plain bug in a state class: a state-management layer that skips rebuilds when the old and new state are equal will now skip the rebuild that was supposed to show the new badge.

## Do

```dart
import 'package:equatable/equatable.dart';

class InboxState extends Equatable {
  const InboxState(this.messages, this.unreadCount);

  final List<String> messages;
  final int unreadCount;

  @override
  List<Object?> get props => [messages, unreadCount];
}
```

### `EquatableMixin` is checked the same way

```dart
import 'package:equatable/equatable.dart';

// Don't
class Session with EquatableMixin {
  Session(this.userId, this.expiresAt);

  final String userId;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [userId];
}
```

```dart
import 'package:equatable/equatable.dart';

// Do
class Session with EquatableMixin {
  Session(this.userId, this.expiresAt);

  final String userId;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [userId, expiresAt];
}
```

### Static fields are not instance state

Only the class's own instance fields are required. A `static const` is shared, not per-instance, so it is never expected in `props`:

```dart
import 'package:equatable/equatable.dart';

// No warning
class Username extends Equatable {
  const Username(this.value);

  final String value;
  static const maxLength = 100;

  @override
  List<Object?> get props => [value];
}
```

## Known limitations

**Only fields declared on the class itself are checked.** Inherited fields are the parent's business, and it lists them in its own `props`.

**`props` must return a list literal directly.** A getter that delegates — `=> _buildProps()` — cannot be read statically, and the class is skipped entirely. A literal containing a spread (`=> [...super.props, name]`) is still read.

**Names are matched as identifiers anywhere inside the literal**, not as bare entries. `props => [name.toLowerCase()]` counts as listing `name`, so a field that only appears inside an expression satisfies the check.

**See also:** [equatable package](https://pub.dev/packages/equatable)

## Configuration

This rule is in **no preset**, so it is off unless you enable it by name:

```yaml
# many_lints.yaml
rules:
  list_all_equatable_fields: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  list_all_equatable_fields: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
- [`prefer_overriding_parent_equality`](/many_lints/docs/rules/collection-type/prefer-overriding-parent-equality/) — Override == and hashCode when the parent class overrides them.
- [`prefer_equatable_mixin`](/many_lints/docs/rules/type-annotations/prefer-equatable-mixin/) — Prefer using EquatableMixin instead of extending Equatable.
- [`prefer_add_all`](/many_lints/docs/rules/collection-type/prefer-add-all/) — Replace an add-only loop with addAll.
