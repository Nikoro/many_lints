---
title: Configuration
description: How to install and configure many_lints in your Flutter & Dart project.
---

## Installation

Add `many_lints` to the **top-level** `plugins` section in your `analysis_options.yaml` file (NOT under `analyzer:`):

```yaml
plugins:
  many_lints: ^1.0.0
```

The analysis server will automatically download and resolve the plugin from [pub.dev](https://pub.dev/packages/many_lints). There is no need to add it to your `pubspec.yaml`.

> **Requires Dart 3.11+ (Flutter 3.41+)**

## Extended syntax

You can use the extended syntax to pin a version:

```yaml
plugins:
  many_lints:
    version: ^1.0.0
```

## Local development

For local development or when using many_lints from a cloned repository, use the `path` option:

```sh
git clone https://github.com/Nikoro/many_lints.git /path/to/many_lints
```

```yaml
plugins:
  many_lints:
    path: /path/to/many_lints
```

Git dependencies are also supported and use the same syntax as package
dependencies:

```yaml
plugins:
  many_lints:
    git: https://github.com/Nikoro/many_lints.git
```

## Choosing a preset

**Every rule is off by default.** Installing the plugin reports nothing until you pick a
preset — so adding `many_lints` to an existing codebase never floods it with warnings on
day one.

Pick a preset with the `preset:` key, in **either** of the two config locations described
below:

```yaml
# many_lints.yaml
preset: recommended
```

:::caution[No diagnostics after installing?]
That is the intended behaviour, not a broken setup. Add `preset: recommended` and restart
the analysis server.
:::

### The presets

| Preset | Rules | What it contains |
|--------|-------|------------------|
| `none` | 0 | Nothing. The default, and the explicit way to opt out. |
| `core` | 31 | Near-certain bugs only. |
| `recommended` | 79 | `core` plus idiomatic, uncontroversial Dart and Flutter practice. |
| `all` | 156 | Every rule, including opinionated ones. |

Each preset builds on the one above it, the same way `package:lints/recommended.yaml`
includes `core.yaml` — moving up a tier only ever adds rules.

**`core`** flags what is almost certainly a bug: a condition that is always true, a cast
that can never succeed, an undisposed controller, an `emit(state)` that is silently
dropped. Near-zero false positives and no stylistic judgement, so it is safe to adopt in
a large legacy codebase.

**`recommended`** is the tier most projects want. It adds widely-agreed practice — using
`containsKey` over `keys.contains`, passing an existing future to a `FutureBuilder`,
keeping enum switches exhaustive. It deliberately excludes anything that imposes an
architecture, a naming scheme, or a contested style choice.

**`all`** turns on the entire catalogue, including rules that enforce a particular taste
(widget-swapping rules, naming conventions, shorthand preferences). This is also the
setting that reproduces the pre-1.0.0 behaviour, when every rule was on by default.

Rules that do nothing until you configure them — `avoid_banned_imports`,
`use_class_suffix` and the rest of the `banned_*` family — are in no preset, since an
unconfigured banned-list has nothing to report.

### Adjusting a preset

`enabled:` overrides the preset for one rule, in either direction, so you never have to
restate a preset's contents to tweak it:

```yaml
# many_lints.yaml
preset: recommended
rules:
  # Add a rule the preset leaves out.
  use_class_suffix:
    enabled: true
    entries:
      - class: Bloc
        suffix: Bloc
  # Drop one the preset includes.
  avoid_only_rethrow:
    enabled: false
```

When a rule needs nothing but on-or-off, the terse spelling works too:

```yaml
rules:
  prefer_type_over_var: true
  avoid_only_rethrow: false
```

### Severity

`preset:` and `enabled:` decide *whether* a rule runs. To change how loudly it reports,
use the analyzer's own `diagnostics:` key:

```yaml
plugins:
  many_lints:
    version: ^1.0.0
    diagnostics:
      avoid_equal_expressions: error   # error | warning | info
```

:::note
`diagnostics:` can also disable a rule, but it cannot enable one that a preset left off —
that is what `enabled:` is for. Prefer keeping enablement in one place and using
`diagnostics:` only for severity.
:::

## Excluding paths per rule

A preset turns a rule on everywhere. To keep a rule on but silence it for
certain paths, write a `rules:` block — in **either** of these two places, whichever
you prefer.

### Option A — in `analysis_options.yaml`

Under a top-level `many_lints:` key. Note it is top-level: a sibling of `plugins:`,
not nested inside it.

```yaml
# analysis_options.yaml
plugins:
  many_lints: ^1.0.0

many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - test/**
        - "**/*.g.dart"
```

### Option B — in a separate `many_lints.yaml`

Placed next to your `pubspec.yaml`.

```yaml
# many_lints.yaml
rules:
  avoid_only_rethrow:
    exclude:
      - test/**
      - "**/*.g.dart"
```

### Which to pick

Both are fully equivalent — the `rules:` block is identical, it just sits one level
deeper in Option A. Use Option A to keep everything in one file, or Option B to keep
lint configuration separate.

### What `exclude` accepts

Every rule supports `exclude`. Each `exclude` sits under one rule and affects only that
rule — excluding a path from `avoid_only_rethrow` says nothing about the other rules.
To skip a path for several rules, give each of them its own `exclude`.

Patterns are globs matched against the path relative to the package root, using the same
glob semantics as the analyzer's own `analyzer: exclude:`. A plain path is a valid
pattern too, and the list can hold as many entries as you need:

```yaml
rules:
  avoid_only_rethrow:
    exclude:
      - lib/legacy/parser.dart      # one specific file
      - lib/generated/**            # a whole directory tree
      - "**/*.g.dart"               # every generated file
  prefer_type_over_var:
    exclude:
      - test/**                     # a different rule, its own list
```

:::caution[If you create both]
`many_lints.yaml` wins outright and the `analysis_options.yaml` section is ignored —
the two are **not** merged.
:::

:::note[Two limitations worth knowing]
The `rules:` block cannot live *inside* `plugins: many_lints:`. The analyzer accepts
only enable/disable and severity there, and reports any other key as an unsupported
option — which is why the configuration sits either one level up or in its own file.

The top-level `many_lints:` section is also **not** inherited through `include:`,
because the analyzer never parses it. If you share a base `analysis_options.yaml`
across packages, use Option B in each package instead.
:::

## Limiting a rule to certain paths

`include` is the inverse of `exclude`: the rule runs **only** where it matches.

```yaml
rules:
  avoid_banned_imports:
    include:
      - lib/domain/**       # architectural rules are most useful scoped
```

Like `exclude`, it takes globs relative to the package root, and a bare string works
where you only need one pattern (`include: lib/domain/**`).

Omitting `include`, or leaving it empty, means "everywhere" — the default. When a file
matches both lists `exclude` wins, so the two only ever narrow further and you never
have to reason about which was written first.

## Adding a note to a rule's message

`message` appends a sentence to every diagnostic a rule reports, which turns a generic
lint into your team's house style:

```yaml
rules:
  avoid_border_all:
    message: Use AppBorders from our design system.
```

```
warning • Prefer Border.fromBorderSide over Border.all. Use AppBorders from our
          design system. • many_lints/avoid_border_all
```

The rule's own text is kept and the diagnostic code is unchanged, so `// ignore:`
comments, severity overrides and quick fixes all keep working.

Both `include` and `message` work on **every** rule, exactly like `exclude`.

## Per-rule options

Beyond `exclude`, `include` and `message`, **52 rules** accept options that change *what*
they report. Those rules carry a <span class="rule-badge rule-badge--config">Configurable</span>
badge on their page, and every option is documented there with its type and default.

Options go in the same `rules:` block as `exclude`, in whichever of the two files you chose
above:

```yaml
# many_lints.yaml
rules:
  prefer_container:
    exclude:
      - test/**            # works on every rule
    min_sequence: 4        # an option, specific to this rule
```

Every option defaults to the rule's previous behaviour, so adding this package's
options never changes results until you set one.

| Rule | Options |
|------|---------|
| [`always_remove_listener`](/many_lints/docs/rules/resource-management/always-remove-listener/) | `state_base_classes` |
| [`avoid_banned_annotations`](/many_lints/docs/rules/architecture/avoid-banned-annotations/) | `banned` |
| [`avoid_banned_exports`](/many_lints/docs/rules/architecture/avoid-banned-exports/) | `banned` |
| [`avoid_banned_imports`](/many_lints/docs/rules/architecture/avoid-banned-imports/) | `banned` |
| [`avoid_banned_names`](/many_lints/docs/rules/architecture/avoid-banned-names/) | `banned` |
| [`avoid_banned_types`](/many_lints/docs/rules/architecture/avoid-banned-types/) | `banned` |
| [`avoid_collection_methods_with_unrelated_types`](/many_lints/docs/rules/collection-type/avoid-collection-methods-with-unrelated-types/) | `strict` |
| [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/) | `min_lines` |
| [`avoid_default_tostring`](/many_lints/docs/rules/code-quality/avoid-default-tostring/) | `report_enums` |
| [`avoid_duplicate_bloc_event_handlers`](/many_lints/docs/rules/bloc-riverpod/avoid-duplicate-bloc-event-handlers/) | `additional_methods` |
| [`avoid_duplicate_collection_elements`](/many_lints/docs/rules/collection-type/avoid-duplicate-collection-elements/) | `ignore_literals` |
| [`avoid_empty_setstate`](/many_lints/docs/rules/state-management/avoid-empty-setstate/) | `state_base_classes` |
| [`avoid_hooks_outside_build`](/many_lints/docs/rules/hook-rules/avoid-hooks-outside-build/) | `additional_methods` |
| [`avoid_inherited_widget_in_initstate`](/many_lints/docs/rules/state-management/avoid-inherited-widget-in-initstate/) | `state_base_classes` |
| [`avoid_late_context`](/many_lints/docs/rules/state-management/avoid-late-context/) | `state_base_classes` |
| [`avoid_missing_completer_stack_trace`](/many_lints/docs/rules/async-safety/avoid-missing-completer-stack-trace/) | `require_inside_catch` |
| [`avoid_misused_hooks`](/many_lints/docs/rules/hook-rules/avoid-misused-hooks/) | `ignored_names`, `ignored_widgets` |
| [`avoid_mounted_in_setstate`](/many_lints/docs/rules/state-management/avoid-mounted-in-setstate/) | `state_base_classes` |
| [`avoid_not_encodable_in_to_json`](/many_lints/docs/rules/collection-type/avoid-not-encodable-in-to-json/) | `allowed_types` |
| [`avoid_only_rethrow`](/many_lints/docs/rules/control-flow/avoid-only-rethrow/) | `ignore_typed_catches` |
| [`avoid_passing_async_when_sync_expected`](/many_lints/docs/rules/async-safety/avoid-passing-async-when-sync-expected/) | `ignore_widget_callbacks`, `ignored_parameters` |
| [`avoid_recursive_widget_calls`](/many_lints/docs/rules/widget-best-practices/avoid-recursive-widget-calls/) | `state_base_classes` |
| [`avoid_returning_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-returning-widgets/) | `ignored_names`, `ignored_annotations`, `allow_nullable` |
| [`avoid_state_constructors`](/many_lints/docs/rules/state-management/avoid-state-constructors/) | `state_base_classes` |
| [`avoid_unassigned_stream_subscriptions`](/many_lints/docs/rules/resource-management/avoid-unassigned-stream-subscriptions/) | `ignored_instances` |
| [`avoid_unnecessary_overrides_in_state`](/many_lints/docs/rules/state-management/avoid-unnecessary-overrides-in-state/) | `state_base_classes` |
| [`avoid_unnecessary_setstate`](/many_lints/docs/rules/state-management/avoid-unnecessary-setstate/) | `state_base_classes` |
| [`avoid_unnecessary_stateful_widgets`](/many_lints/docs/rules/state-management/avoid-unnecessary-stateful-widgets/) | `state_base_classes` |
| [`avoid_unrelated_type_casts`](/many_lints/docs/rules/collection-type/avoid-unrelated-type-casts/) | `report_is_checks` |
| [`avoid_unremovable_callbacks_in_listeners`](/many_lints/docs/rules/resource-management/avoid-unremovable-callbacks-in-listeners/) | `additional_methods` |
| [`banned_usage`](/many_lints/docs/rules/architecture/banned-usage/) | `banned` |
| [`check_for_equals_in_render_object_setters`](/many_lints/docs/rules/widget-best-practices/check-for-equals-in-render-object-setters/) | `additional_methods` |
| [`check_is_not_closed_after_async_gap`](/many_lints/docs/rules/async-safety/check-is-not-closed-after-async-gap/) | `additional_methods` |
| [`dispose_fields`](/many_lints/docs/rules/resource-management/dispose-fields/) | `cleanup_methods`, `additional_cleanup_methods`, `state_base_classes` |
| [`dispose_provided_instances`](/many_lints/docs/rules/bloc-riverpod/dispose-provided-instances/) | `cleanup_methods`, `additional_cleanup_methods` |
| [`emit_new_bloc_state_instances`](/many_lints/docs/rules/bloc-riverpod/emit-new-bloc-state-instances/) | `additional_methods` |
| [`prefer_class_destructuring`](/many_lints/docs/rules/collection-type/prefer-class-destructuring/) | `min_occurrences`, `ignored_types` |
| [`prefer_container`](/many_lints/docs/rules/widget-replacement/prefer-container/) | `min_sequence` |
| [`prefer_immutable_bloc_state`](/many_lints/docs/rules/bloc-riverpod/prefer-immutable-bloc-state/) | `name_pattern` |
| [`prefer_private_named_parameters`](/many_lints/docs/rules/code-quality/prefer-private-named-parameters/) | `only_same_name` |
| [`prefer_shorthands_with_constructors`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-constructors/) | `classes`, `additional_classes` |
| [`prefer_single_setstate`](/many_lints/docs/rules/code-quality/prefer-single-setstate/) | `state_base_classes` |
| [`prefer_single_widget_per_file`](/many_lints/docs/rules/widget-best-practices/prefer-single-widget-per-file/) | `ignore_private_widgets`, `ignore_visible_for_testing` |
| [`prefer_spacing`](/many_lints/docs/rules/widget-best-practices/prefer-spacing/) | `min_children` |
| [`prefer_switch_expression`](/many_lints/docs/rules/control-flow/prefer-switch-expression/) | `allow_fallthrough_cases` |
| [`prefer_switch_with_enums`](/many_lints/docs/rules/pattern-matching/prefer-switch-with-enums/) | `ignore_contains` |
| [`proper_super_calls`](/many_lints/docs/rules/control-flow/proper-super-calls/) | `state_base_classes` |
| [`require_atomic_async_updates`](/many_lints/docs/rules/async-safety/require-atomic-async-updates/) | `include_local_variables` |
| [`use_class_prefix`](/many_lints/docs/rules/class-naming/use-class-prefix/) | `entries`, `ignore_private` |
| [`use_class_suffix`](/many_lints/docs/rules/class-naming/use-class-suffix/) | `entries`, `ignore_private` |
| [`use_gap`](/many_lints/docs/rules/widget-best-practices/use-gap/) | `min_children` |
| [`use_sliver_prefix`](/many_lints/docs/rules/widget-best-practices/use-sliver-prefix/) | `state_base_classes` |

`state_base_classes` is accepted by every rule that only applies inside a
`StatefulWidget`'s `State`. Name a base class that does **not** extend Flutter's
`State` and those rules will treat it as one; an intermediate `BaseState<T>` that
already extends `State` is recognised without any configuration.

Each option is documented with its type and default in the **Options** section
of the rule's own page.

### Naming conventions

Option names follow a fixed vocabulary, so the same idea always reads the same way:

| Pattern | Meaning |
|---------|---------|
| `max_<unit>` / `min_<unit>` | A numeric bound; the unit is always named |
| `ignore_<singular>` | A toggle that skips a whole class of thing (`ignore_private`) |
| `ignored_<plural>` | A list of specific things to skip |
| `<plural>` | **Replaces** a built-in list (`cleanup_methods`) |
| `additional_<plural>` | **Extends** a built-in list (`additional_cleanup_methods`) |
| `name_pattern` | A regular expression matched against a name |
| `entries` | A list of maps, for rules driven entirely by what you configure |

Prefer `additional_*` over restating a built-in list: a copied-out default silently
misses any entry added in a later release.

### Invalid values never break analysis

A misspelled key is ignored, and a wrong-typed value falls back to the default rather
than throwing. This is deliberate — a plugin cannot report problems against a YAML
file, so a bad option cannot be surfaced as a diagnostic. If an option seems to have
no effect, check its spelling and type against the rule's page.

## Suppressing diagnostics

To suppress a specific lint, use comments:

```dart
// ignore: many_lints/prefer_center_over_align
const Align(...);

// ignore_for_file: many_lints/use_class_suffix
```

:::caution[The `many_lints/` prefix is required]
Unlike SDK lints, a plugin diagnostic is only silenced when the rule name is prefixed with the plugin name. A bare `// ignore: prefer_center_over_align` has **no effect** — the analyzer matches the plugin name alongside the rule name, and a comment without a prefix carries none, so it never matches.

The prefix is the package name used as the key under `plugins:` in
`analysis_options.yaml`.

```dart
// ignore: prefer_center_over_align             // ❌ does nothing
// ignore: many_lints/prefer_center_over_align  // ✅ works
```

Suppressing by diagnostic type also works, and needs the `type=` form — plain `// ignore: lint` has no effect. Note this silences *every* lint on that line, including SDK ones:

```dart
// ignore: type=lint
```
:::

## Restarting the analysis server

:::caution
After any change to the `plugins` section, you must restart the Dart Analysis Server for changes to take effect.
:::

**VS Code**: Open the command palette (`Cmd+Shift+P` / `Ctrl+Shift+P`) and run `Dart: Restart Analysis Server`.

**Android Studio / IntelliJ**: Go to `File → Invalidate Caches / Restart`, or use the Dart Analysis panel to restart.
