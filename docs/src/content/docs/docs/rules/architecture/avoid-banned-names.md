---
title: avoid_banned_names
description: "Ban specific identifiers from being used as declaration names"
sidebar:
  label: avoid_banned_names
---

<span class="rule-badge rule-badge--version">Unreleased</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Architecture</span>

Flags declarations named with an identifier you ban, optionally only inside the directories you name. Enforces a project's vocabulary: ban `data`, `temp` and `manager` as meaningless, or reserve a domain term for the one thing it should mean.

**This rule reports nothing until you configure it.**

## Why use this rule

Names like `data`, `info`, `temp` and `manager` survive because they are never wrong — every value is data and every class manages something. That is exactly what makes them useless: they tell the next reader nothing the type did not already say, and they cluster, so a file ends up with `data`, `userData` and `dataList` in one scope.

A banned-name list is also how a team keeps a domain term precise. If `Order` means a customer purchase, banning it as a variable name for a sort order stops the two senses from mixing in the same codebase.

**See also:** [Effective Dart: naming](https://dart.dev/effective-dart/design#names), [Dart style guide: do use terms consistently](https://dart.dev/effective-dart/design#do-use-terms-consistently)

## Don't

```dart
// With an entry banning 'data', 'temp', 'manager':
final data = fetchUsers();      // LINT: says nothing the type didn't
void process(int temp) {}       // LINT
class Manager {}                // LINT
```

## Do

```dart
final users = fetchUsers();

void process(int celsius) {}

class UserDirectory {}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_banned_names: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  avoid_banned_names:
    banned:
      - deny: ['data', 'temp', 'info', 'manager']
        message: 'Name it for what it holds.'
      - deny_pattern: ['.*Impl']
        message: 'Name the implementation for how it differs.'
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `banned` | list of maps | `[]` | The entries to enforce. With none, the rule reports nothing |

Each entry accepts:

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `deny` | string or list | one of `deny` / `deny_pattern` | Identifiers banned by **exact** match |
| `deny_pattern` | string or list | one of `deny` / `deny_pattern` | Regular expressions, anchored to the whole name |
| `in` | list of globs | no | Paths, relative to the package root, where the entry applies. Omit to apply everywhere |
| `message` | string | no | A project-specific explanation appended to the diagnostic |

### What is checked

Variables, parameters, methods, functions, classes, mixins, enums, extension types, and type parameters — every place a name is **chosen**.

References are deliberately *not* reported. A reference is not separately fixable (renaming the declaration fixes every use), so reporting them would bury the one line you can act on under diagnostics you cannot.

Because `deny` matches exactly, banning `data` leaves `userData` and `dataSource` alone. Use `deny_pattern` to match by shape — and note it anchors to the whole name, so `.*Impl` matches `UserImpl` but not `ImplementationDetail`.

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
