# Configurable Rules — Remaining Work

**Researched:** 2026-08-08 · **Revised:** 2026-08-09 (Phases 1–3 shipped, sections pruned)
**Status:** Tier 1 and the banned-* family are implemented. Tier 2 structural work and
the Tier 3 per-rule options remain.

Read [config-cookbook.md](../.agents/skills/new-lint/config-cookbook.md) before implementing
anything here — it documents what the analyzer can and cannot do, and why.

---

## Baseline (verified 2026-08-09)

| Fact | Value |
|------|-------|
| Rule files in `lib/src/rules/` | **138** |
| Rules reading an option | **10** — 4 directly, 6 via shared helpers (below) |
| Accessors available | `boolOption`, `intOption`, `stringListOption`, `entriesOption`, `nameSetOption` |

Started at 1/133. another linter, for reference, configures 147 of 514 rules (28.6%).

### Already shipped — do not redo

| Was | Now |
|-----|-----|
| §4.1 map accessor (the blocker) | `entriesOption` at `lib/src/rule_config.dart:76`, plus `nameSetOption` implementing the replace/append pair |
| §4.2–4.3 banned-* family | All six rules ship (`avoid_banned_imports/_types/_names/_exports/_annotations`, `banned_usage`) reading `banned:` via `lib/src/banned_entry.dart:101`, with docs pages |
| §2.1 shorthand `classes` | `classes` + `additional_classes`; the "fork the package" docstring is rewritten |
| §2.2 affix rules | `lib/src/class_affix_validator.dart` — `AffixKind`, `entries`, per-entry and rule-wide `ignore_private` |
| §2.3 safe thresholds | `min_sequence` (`prefer_container`), `min_occurrences` (`prefer_class_destructuring`). The two unsafe ones stayed unexposed, correctly |
| §2.4 `cleanup_methods` | `lib/src/disposal_utils.dart:47`, replace + append |
| §6 all four bugs | `'@override'` fixed; `IntrinsicHeight`/`IntrinsicWidth`/`LimitedBox` now explicitly excluded with a comment; `HookConsumerWidget` added; dead `isStableReference` deleted |

The naming vocabulary below was locked in by that work and is now load-bearing — new options
must match it.

---

## 1. Naming conventions (locked in — follow these)

another linter's biggest self-inflicted wound is naming sprawl: six spellings for "a numeric limit"
(`max-number`, `max-length`, `threshold`, `acceptable-level`, `min-sequence`, `break-on`) and
three for "list of names to skip". `avoid-long-files` uses `max-length` for *lines* while
`prefer-correct-type-name` uses it for *characters*.

| Concept | Our key | Notes |
|---------|---------|-------|
| Numeric limit, upper bound | `max_<unit>` | always name the unit |
| Numeric limit, lower bound | `min_<unit>` | `min_sequence`, `min_occurrences` |
| Behavioural toggle | `ignore_<singular>` | `ignore_private`, `ignore_nested` |
| List of specific exclusions | `ignored_<plural>` | `ignored_names`, `ignored_types` |
| **Replace** a built-in list | `<plural>` | `cleanup_methods: [...]` |
| **Append** to a built-in list | `additional_<plural>` | `additional_cleanup_methods: [...]` |
| Regex on a name | `name_pattern` | one spelling only |
| List of multi-field objects | `entries` / concept name | `banned:`, `entries:` — name it after its shape |

`nameSetOption(key, defaultValue:)` implements the replace/append pair for you; use it rather
than reading two options by hand.

**Rules for every option:** the default must reproduce today's behaviour exactly; prefer options
that make a rule *quieter*; never add an option that duplicates `exclude` or `severity`.

---

## 2. Universal `include:` and `message:` — highest remaining value

Implement once in `ManyLintsRule`, applies to all 138 rules. This is the best
effort-to-value ratio left in the document.

- **`include:`** — inverse of `exclude`; "only run this rule in `lib/features/**`".
  Architectural rules are far more useful scoped than global. `exclude` is already applied at
  the reporter seam (`ManyLintsRule.reporter`), so `include` slots into the same place —
  the resolved-config path is already there and tested.
- **`message:`** — append a project-specific sentence to the diagnostic ("Use our `AppSpacing`
  tokens instead"). Turns a generic lint into house style with one line of YAML. Needs the
  reporter wrapper to rewrite the diagnostic message rather than just suppress it, so it is
  the more invasive of the two.

Note `rule_config.dart:225` already documents an `include:`-inheritance caveat in a comment —
reconcile that text with whatever actually ships.

---

## 3. Tier 3 — per-rule options

Grouped by the another linter precedent that validates them. Defaults preserve current behaviour.
None of these are implemented.

| Our rule | Proposed option | Default | another linter precedent |
|----------|-----------------|---------|---------------|
| `prefer_single_widget_per_file` | `ignore_private_widgets`, `ignore_visible_for_testing` | `false`, `false` | exact match |
| `avoid_returning_widgets` | `ignored_names`, `ignored_annotations`, `allow_nullable` | `[]`, `[]`, `false` | exact match |
| `avoid_commented_out_code` | `min_lines` | `1` | exact match |
| `avoid_collection_methods_with_unrelated_types` | `strict` | `true` | exact match |
| `avoid_default_tostring` | `ignore_enums` | `false` | exact match |
| `avoid_duplicate_collection_elements` | `ignore_literals` | `false` | exact match |
| `prefer_switch_expression` | `ignore_fallthrough_cases` | `false` | exact match |
| `prefer_switch_with_enums` | `ignore_contains` | `false` | exact match |
| `prefer_private_named_parameters` | `only_same_name` | `true` | exact match |
| `prefer_class_destructuring` | `ignored_types` | `[]` | exact match (`min_occurrences` done) |
| `avoid_duplicate_bloc_event_handlers` | `additional_methods` | `[]` | exact match |
| `check_is_not_closed_after_async_gap` | `additional_methods` | `[]` | exact match |
| `avoid_hooks_outside_build` | `additional_methods` | `[]` | exact match |
| `avoid_misused_hooks` | `ignored_widgets` | `[]` | exact match |
| `prefer_immutable_bloc_state` | `name_pattern` | `State$` | exact match |
| `dispose_fields` | `ignore_blocs` | `false` | exact match |
| `avoid_unassigned_stream_subscriptions` | `ignored_instances` | `[]` | analogous |
| `prefer_spacing` / `use_gap` | `min_children`, `ignored_widgets` | — | our own |

### Deliberately NOT configurable — decision, not an oversight

Per the cookbook, "prefer a rule that is right by default over a rule with knobs." These encode
correctness, not preference, and an option would only let users hide real bugs:
`avoid_conditional_hooks`, `notifier_build`, `missing_provider_scope`,
`avoid_unsafe_collection_methods`, `use_ref_and_state_synchronously`, `proper_super_calls`,
`avoid_empty_setstate`, `list_all_equatable_fields`.

Two more that were considered and rejected during Tier 1:

- **`prefer_switch_with_enums._threshold`** is reused for two different meanings — comparison
  count and collection-element count. Exposing one key for both would repeat exactly the another linter
  mistake §1 exists to prevent. Split into `min_comparisons` / `min_elements` or leave alone.
- **`avoid_commented_out_code._maxComments = 500`** is an internal performance bail-out that
  silently stops analysing a file past 500 comments — not a user-facing threshold. Exposing it
  would advertise a soft correctness limit. Better: make the bail-out report a diagnostic
  instead of failing silently.

---

## 4. Structural — only if demanded

Both need shared-helper extraction first, and both were deferred deliberately.

### 4.1 `package_names` — the `TypeChecker` monoculture

`packageName:` is hardcoded at **136 sites**: `flutter` 87, `hooks_riverpod` 12,
`flutter_riverpod` 12, `bloc` 11, `riverpod` 8, `flutter_bloc` 6, `flutter_hooks` 5,
`equatable` 3, `sliver_tools` / `riverpod_annotation` 1 each.

Any team using a **fork, re-export, or wrapper package** silently gets zero diagnostics, with
no signal explaining why. That is a "rules mysteriously don't work" bug class, not a
preference. Should be a **global** config section rather than per-rule. Deferred until someone
reports it; noted so the cost is known.

### 4.2 The `State` base-class cluster

**14 files** hardcode `TypeChecker.fromName('State', packageName: 'flutter')`, spread across
multiple lines — a single-line grep for `fromName('State'` misses it, which is how an earlier
pass under-counted this.

Affected: `dispose_fields`, `prefer_single_setstate`, `avoid_unnecessary_overrides_in_state`,
`avoid_unnecessary_setstate`, `use_sliver_prefix`, `avoid_empty_setstate`, `proper_super_calls`,
`avoid_unnecessary_stateful_widgets`, `avoid_recursive_widget_calls`, `always_remove_listener`,
`avoid_mounted_in_setstate`, `avoid_state_constructors`, `avoid_inherited_widget_in_initstate`.

A shared `state_base_classes` option would fix all 14 at once, but only routed through a shared
helper that does not exist yet.

**Prerequisite, and worth doing regardless of config:** four rules define four different
memberships for "State lifecycle methods." Reconciling those is a correctness cleanup that
should precede any config work here.

---

## 5. New rule ideas not in another linter

- **`require_import_alias`** — force `import 'package:x/x.dart' as x;` for configured packages.
  another linter has `prefer-named-imports`; ours would allow a required-alias *pattern*.
- **`banned_widget_in_path`** — a Flutter-flavoured `avoid_banned_types`: no `Scaffold` inside
  `lib/widgets/atoms/**`. Enforces design-system layering, a real and common need. May be
  reachable as configuration of the existing `avoid_banned_types` rather than a new rule.
- **`avoid_banned_dependencies_in_layer`** — combine import bans with pubspec awareness.
  ⚠️ Blocked: we cannot analyse pubspec, because `PluginServer` never invokes `pubspecVisitor`.
  Import-level only.

---

## Sequencing

1. **§2 universal `include:`** — one change, 138 rules, the seam already exists. Do `message:`
   after, since it needs the reporter to rewrite rather than suppress.
2. **§3 Tier 3 breadth** — each a few hours; work down the table by demand.
3. **§4 structural** — only when someone reports the fork/wrapper problem. Extract the shared
   helper and reconcile the lifecycle-method sets first.

### Testing

`AnalysisRuleTest` **cannot** test configuration — there is no package root. Every option needs
a `PluginServer` test following `test/rule_config_test.dart`, and every negative assertion must
be paired with an **asymmetric positive** one. A test proving only silence cannot distinguish
"the option worked" from "the rule never fired" — this already produced one round of
vacuously-passing tests in this repo.

### Docs

Each configurable rule needs its `## Configuration` section extended with an options table
(name, type, default, description) per the cookbook template, always stating the default and
the `include:`-inheritance caveat.
