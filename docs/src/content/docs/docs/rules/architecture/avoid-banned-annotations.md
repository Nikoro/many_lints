---
title: avoid_banned_annotations
description: "Ban specific annotations, optionally scoped by directory"
sidebar:
  label: avoid_banned_annotations
---

<span class="rule-badge rule-badge--version">Unreleased</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Architecture</span>

Flags annotations you ban, optionally only inside the directories you name. The motivating case is scope: `@visibleForTesting` is reasonable on a helper and wrong in a production directory.

**This rule reports nothing until you configure it.**

## Why use this rule

`@visibleForTesting` is a way of saying "this is private, except to tests". That is a fair trade in a utility, but in a core production type it is how encapsulation erodes: the annotation makes the widening explicit without making it rare, and nothing pushes back when the next test wants one more member.

Banning it in the directories that hold your most-depended-on code forces the alternative — inject the seam the test needs rather than opening the type — while leaving it available everywhere else.

**See also:** [`package:meta` annotations](https://pub.dev/documentation/meta/latest/meta/meta-library.html), [`visibleForTesting` API docs](https://pub.dev/documentation/meta/latest/meta/visibleForTesting-constant.html)

## Don't

```dart
// in lib/production/payment_service.dart
//
// With an entry banning 'visibleForTesting' in lib/production/**:
class PaymentService {
  @visibleForTesting  // LINT: widens visibility in production code
  void resetLedger() {}
}
```

## Do

```dart
// in lib/production/payment_service.dart
//
// Inject what the test needs to control instead of exposing internals.
abstract class Ledger {
  void reset();
}

class PaymentService {
  const PaymentService(this._ledger);

  final Ledger _ledger;

  void refundAll() => _ledger.reset();
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_banned_annotations: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  avoid_banned_annotations:
    banned:
      - deny: ['visibleForTesting']
        in: ['lib/production/**']
        message: 'Production code must not widen visibility for tests.'
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `banned` | list of maps | `[]` | The entries to enforce. With none, the rule reports nothing |

Each entry accepts:

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `deny` | string or list | one of `deny` / `deny_pattern` | Annotation names banned by **exact** match, written without the `@` |
| `deny_pattern` | string or list | one of `deny` / `deny_pattern` | Regular expressions, anchored to the whole name |
| `in` | list of globs | no | Paths, relative to the package root, where the entry applies. Omit to apply everywhere |
| `message` | string | no | A project-specific explanation appended to the diagnostic |

Write the annotation name without the `@`. Both `@visibleForTesting` and the prefixed `@meta.visibleForTesting` match a single `visibleForTesting` entry, so an import prefix cannot slip past the rule.

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
