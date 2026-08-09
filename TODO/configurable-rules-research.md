# Configurable Rules — Remaining Work

**Researched:** 2026-08-08 · **Revised:** 2026-08-09 (all phases shipped)
**Status:** Everything actionable in this document is implemented. What is left is
§4.1 `package_names`, deliberately deferred until someone reports it, and the §5 new
rule ideas.

Read [config-cookbook.md](../.agents/skills/new-lint/config-cookbook.md) before implementing
anything here — it documents what the analyzer can and cannot do, and why.

---

## Baseline (verified 2026-08-09)

| Fact | Value |
|------|-------|
| Rule files in `lib/src/rules/` | **138** |
| Rules reading configuration | **40** (29%) |
| Rules supporting `exclude` / `include` / `message` | **138** (all, via `ManyLintsRule`) |
| Accessors available | `boolOption`, `intOption`, `stringListOption`, `entriesOption`, `nameSetOption`, `patternOption` |

Started at 1/133. another linter, for reference, configures 147 of 514 rules (28.6%) — and every
one of theirs also takes a universal layer, which is what `include`/`message` match.

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

## 2. Universal `include:` and `message:` — shipped

Both live in `ManyLintsRule` and apply to all 138 rules.

- **`include:`** — inverse of `exclude`, resolved in `ResolvedRuleConfig.forPath`
  alongside it. `exclude` is checked first so a file matching both is skipped; both
  only narrow, so there is no ordering for users to learn.
- **`message:`** — appends a sentence to every diagnostic the rule reports.

The `message:` implementation is worth knowing about before touching that seam, because
two obvious approaches do not work. `DiagnosticReporter` keeps its listener in a private
field with no accessor, so an incoming reporter cannot be unwrapped; and
`AnalysisRule.reportAt*` delegate to private, non-virtual helpers, so they cannot be
overridden either. What works is subclassing `DiagnosticReporter` and overriding the
public `reportError` — every path (`atNode`/`atToken`/`atSourceRange` → `atOffset`)
funnels through it — and handing that subclass a forwarding listener that calls the
*original* reporter's `reportError`. The rebuilt `Diagnostic` keeps its
`diagnosticCode`, so ignores, severity overrides and the fix registry are unaffected.
Full write-up in the cookbook.

---

## 3. Tier 3 — per-rule options

Shipped. Defaults reproduce the previous behaviour exactly.

| Our rule | Option | Default |
|----------|--------|---------|
| `prefer_single_widget_per_file` | `ignore_private_widgets`, `ignore_visible_for_testing` | `true`, `false` |
| `avoid_returning_widgets` | `ignored_names`, `ignored_annotations`, `allow_nullable` | `[]`, `[]`, `false` |
| `avoid_commented_out_code` | `min_lines` | `1` |
| `avoid_duplicate_collection_elements` | `ignore_literals` | `false` |
| `prefer_switch_with_enums` | `ignore_contains` | `false` |
| `prefer_class_destructuring` | `ignored_types` | `[]` |
| `avoid_hooks_outside_build` | `additional_methods` | `[]` |
| `avoid_misused_hooks` | `ignored_names` | `[]` |
| `prefer_immutable_bloc_state` | `name_pattern` | `State$` |
| `avoid_unassigned_stream_subscriptions` | `ignored_instances` | `[]` |
| `prefer_spacing` | `min_children` | `3` |

Note `prefer_single_widget_per_file.ignore_private_widgets` defaults to **`true`**, not
the `false` this table originally proposed: the rule always skipped private widgets, and
the rule that a default must preserve existing behaviour outranks matching another linter.

### Widening options — the rest of the table

An earlier pass rejected eight of these rows as "the option would control nothing."
That reasoning was wrong: it assumed every option *narrows*. When a rule is already
narrow, the option **widens** it, and the default still reproduces today's behaviour.

| Our rule | Option | Default | Widens to |
|----------|--------|---------|-----------|
| `avoid_default_tostring` | `report_enums` | `false` | Enums without a `toString` override |
| `prefer_private_named_parameters` | `only_same_name` | `true` | A renamed parameter (`_id` from `identifier`) |
| `prefer_switch_expression` | `allow_fallthrough_cases` | `false` | Labels sharing a body, fixed as `case a \|\| b` |
| `avoid_duplicate_bloc_event_handlers` | `additional_methods` | `[]` | A project's own `on`-wrapper |
| `check_is_not_closed_after_async_gap` | `additional_methods` | `[]` | A project's own `emit`-wrapper |
| `avoid_misused_hooks` | `ignored_widgets` | `[]` | (narrowing) exempt a whole widget |
| `use_gap` | `min_children` | `1` | (narrowing) skip short children lists |
| `avoid_collection_methods_with_unrelated_types` | `strict` | `false` | A `dynamic` argument against a known element type |

Two required real work rather than a flag:

- **`allow_fallthrough_cases`** needed the quick fix taught to merge patterns. It now
  accumulates empty cases and joins them with `||` onto the next body, collapsing to `_`
  when the body belongs to `default`. A *trailing* fallthrough has nothing to merge into,
  so rule and fix both still decline it — verified by its own test.
- **`only_same_name: false`** reports a renamed parameter but the fix deliberately
  declines: `this._id` would rename the named argument too, a breaking API change a quick
  fix must not make silently.

### Genuinely not applicable

- **`dispose_fields.ignore_blocs`** — this rule only scans `State`, so there is no Bloc to
  ignore. The widening knob that *does* apply is `state_base_classes`: point it at `Bloc`
  or `Cubit` and their fields get covered. another linter's option is the mirror image of ours.

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

## 4. Structural

### 4.1 `package_names` — the `TypeChecker` monoculture (still open)

`packageName:` is hardcoded at **136 sites**: `flutter` 87, `hooks_riverpod` 12,
`flutter_riverpod` 12, `bloc` 11, `riverpod` 8, `flutter_bloc` 6, `flutter_hooks` 5,
`equatable` 3, `sliver_tools` / `riverpod_annotation` 1 each.

Any team using a **fork, re-export, or wrapper package** silently gets zero diagnostics, with
no signal explaining why. That is a "rules mysteriously don't work" bug class, not a
preference. Should be a **global** config section rather than per-rule. Deferred until someone
reports it; noted so the cost is known.

### 4.2 The `State` base-class cluster — shipped

The 13 rules that pinned `TypeChecker.fromName('State', packageName: 'flutter')` now go
through `isStateElement(rule, element)` in `lib/src/state_base_classes.dart`, which adds
the `state_base_classes` option. All 156 of their existing tests pass unchanged.

Worth being precise about what the option is *for*, because the original framing here was
wrong: an intermediate `BaseState<T>` that extends Flutter's `State` was **never** a
problem — `isSuperOf` walks the hierarchy. The real gap is a state-like base that does
not extend `State` at all, which every one of these rules skipped silently. Configured
names match without a package pin (a locally declared type has no `package:` URI);
Flutter's `State` stays pinned, so a user type coincidentally named `State` cannot widen
a rule by accident.

**The lifecycle-method prerequisite was a false alarm.** This document claimed four rules
define four different memberships for "State lifecycle methods" and that reconciling them
was a correctness cleanup. Reading all four shows they encode genuinely different
concepts and must not be merged:

- `proper_super_calls` — `_superFirstMethods` / `_superLastMethods`, a Flutter API
  *ordering* contract (`initState` calls super first, `dispose` last).
- `avoid_unnecessary_setstate` — `_lifecycleMethods`, the methods that already trigger a
  rebuild, so `setState` in them is redundant.
- `avoid_unnecessary_overrides_in_state` — no list at all; matches any overridden member.
- `dispose_fields` / `avoid_empty_setstate` — no lifecycle list.

Only two of the four have a list, and they answer different questions. Nothing to fix.

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

## What is left

1. **§4.1 `package_names`** — still deferred, still the right call until someone reports
   the fork/wrapper problem. It is the only item here with a known user-visible cost.
2. **§5 new rule ideas** — `require_import_alias` and `banned_widget_in_path`; the latter
   may need no new rule at all, only configuration of `avoid_banned_types`.
Per-rule docs pages are done: every configurable rule now carries an `## Options` table,
and the configuration page lists all 24 in one place.

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
