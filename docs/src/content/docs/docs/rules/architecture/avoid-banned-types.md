---
title: avoid_banned_types
description: "Ban specific types from being named, optionally scoped by directory"
sidebar:
  label: avoid_banned_types
---

<span class="rule-badge rule-badge--version">Unreleased</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Architecture</span>

Flags any mention of a type you ban, optionally only inside the directories you name. Useful for retiring a deprecated model, keeping a platform type out of shared code, or confining a design-system widget to the layer that owns it.

**This rule reports nothing until you configure it.**

## Why use this rule

Deprecation annotations tell you a type is going away; they do not stop new code from reaching for it. During a migration the count of remaining usages is the thing you actually want to drive to zero, and a lint turns that into a number your CI reports instead of a grep somebody remembers to run.

The second use is layering. A design system where atoms must not depend on page-level layout has no way to express that in the type system — `Scaffold` is importable from anywhere. Banning it inside `lib/design_system/atoms/**` states the constraint where it can be checked.

**See also:** [Effective Dart: deprecation](https://dart.dev/tools/linter-rules/deprecated_member_use_from_same_package), [Atomic Design](https://bradfrost.com/blog/post/atomic-web-design/)

## Don't

```dart
// With an entry banning 'LegacyUser':
void greet(LegacyUser user) {}          // LINT: parameter type
LegacyUser find() => LegacyUser('a');   // LINT: return type, and the call
List<LegacyUser> all = [];              // LINT: as a type argument
```

## Do

```dart
void greet(User user) {}

User find() => const User('ada');

List<User> all = [];
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_banned_types: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  avoid_banned_types:
    banned:
      - deny: ['LegacyUser']
        message: 'Use User instead; LegacyUser is removed in v3.'
      - deny: ['Scaffold']
        in: ['lib/design_system/atoms/**']
        message: 'Atoms must not depend on page-level layout.'
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `banned` | list of maps | `[]` | The entries to enforce. With none, the rule reports nothing |

Each entry accepts:

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `deny` | string or list | one of `deny` / `deny_pattern` | Type names banned by **exact** match. Accepts a bare `Name` or a qualified `package:uri#Name` |
| `deny_pattern` | string or list | one of `deny` / `deny_pattern` | Regular expressions, anchored to the whole name |
| `in` | list of globs | no | Paths, relative to the package root, where the entry applies. Omit to apply everywhere |
| `message` | string | no | A project-specific explanation appended to the diagnostic |

Matching is on the type's **declared** name rather than the name as written, so an import prefix cannot hide a usage — `p.LegacyUser` matches a `LegacyUser` entry.

Qualify with `package:uri#Name` when a bare name is ambiguous. Banning `Border` outright would also catch a local class of that name; `package:flutter/src/painting/border.dart#Border` bans only Flutter's.

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.

## Related rules

- [`banned_usage`](/many_lints/docs/rules/architecture/banned-usage/) — bans one *member* of a type rather than the whole type
