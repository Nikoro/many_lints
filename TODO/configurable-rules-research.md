# Configurable Rules — Research & Roadmap

**Date:** 2026-08-08
**Status:** research complete, nothing implemented
**Context:** `many_lints` gained a per-rule config system in v0.9.0 (`lib/src/rule_config.dart`,
`lib/src/many_lints_rule.dart`). Every rule already supports `exclude:` for free. Only **one** rule
reads an actual option today. This document surveys what to do with the new capability.

Read [config-cookbook.md](../.agents/skills/new-lint/config-cookbook.md) before implementing anything
here — it documents what the analyzer can and cannot do, and why.

---

## 0. Baseline (verified 2026-08-08)

| Fact | Value |
|------|-------|
| Rule files in `lib/src/rules/` | **133** (not 135 — `AGENTS.md`/`CLAUDE.md` are not rules) |
| Rules reading an option | **1** — `avoid_only_rethrow` → `ignore_typed_catches` (`avoid_only_rethrow.dart:77`) |
| Available accessors | `boolOption`, `intOption`, `stringListOption` |
| Missing accessors | **map / list-of-maps** (see §4 — blocks the whole banned-* family) |

another linter comparison, from a full sitemap crawl: **147 of 514 another linter rules (28.6%) are configurable.**
We are at 1/133 (0.8%). That gap is the opportunity.

### The one thing another linter does that we should copy wholesale

Every another linter rule — all 514, not just the 147 — accepts a **universal option layer**:
`severity`, `exclude`, `include`, `ignorable`, `message`, `suggest-fixes`, `effort`.
Rule-specific options are *additional*. We already have `exclude` universal via `ManyLintsRule`,
and `severity` via the analyzer's native `diagnostics:` block. The cheap wins still missing are
**`include`** (inverse of exclude) and **`message`** (append a project-specific note to the
diagnostic). Both are implementable once, in the base class, for all 133 rules.

---

## 1. Naming conventions to lock in NOW

another linter's biggest self-inflicted wound is naming sprawl. Their catalogue contains six different
spellings for "a numeric limit" (`max-number`, `max-length`, `threshold`, `acceptable-level`,
`min-sequence`, `break-on`) and three for "list of names to skip" (`ignored-names`, `exceptions`,
`excluded`). `avoid-long-files` uses `max-length` for *lines* while `prefer-correct-type-name` uses
it for *characters*.

**Decide once, hold the line.** Proposed vocabulary (snake_case, matching our existing
`ignore_typed_catches` and Dart lint naming):

| Concept | Our key | Notes |
|---------|---------|-------|
| Numeric limit, upper bound | `max_<unit>` | `max_widgets`, `max_lines` — always name the unit |
| Numeric limit, lower bound | `min_<unit>` | `min_sequence`, `min_occurrences` |
| Behavioural toggle ("skip this class of thing") | `ignore_<singular>` | `ignore_private`, `ignore_nested` |
| List of specific exclusions | `ignored_<plural>` | `ignored_names`, `ignored_types` |
| **Replace** a built-in list | `<plural>` | `cleanup_methods: [...]` |
| **Append** to a built-in list | `additional_<plural>` | `additional_cleanup_methods: [...]` |
| Regex on a name | `name_pattern` | one spelling only |

The `<plural>` / `additional_<plural>` split is the single best idea in another linter's API
(`avoid-collection-mutating-methods` exposes both at once) and costs nothing to adopt.

**Rules for every option**, restating the cookbook: the default must reproduce today's behaviour
exactly; prefer options that make a rule *quieter*; never add an option that duplicates `exclude`
or `severity`.

---

## 2. Tier 1 — Highest leverage (do these first)

### 2.1 `prefer_shorthands_with_constructors` → `classes`

The clearest case in the codebase. `prefer_shorthands_with_constructors.dart:98-103` hardcodes:

```dart
static const _defaultClasses = {'EdgeInsets', 'BorderRadius', 'Radius', 'Border'};
```

…and the docstring immediately above it (`:87-97`) literally tells users to **fork the package**
to change it, closing with "Future versions may support configuration". That future has arrived.
The docstring is now actively wrong and must be rewritten as part of this change.

another linter's equivalent uses `entries` with the identical default list, plus `ignore-nested`.

```yaml
rules:
  prefer_shorthands_with_constructors:
    classes: [EdgeInsets, BorderRadius, Radius, Border, Alignment, TextStyle]
    additional_classes: [MyDesignTokens]   # append instead of replace
```

Effort: ~1h. `stringListOption`, already supported.

### 2.2 Class-suffix rules → `suffix` / `name_pattern` (one change, three rules)

`use_bloc_suffix`, `use_cubit_suffix`, `use_notifier_suffix` all extend the shared
`ClassSuffixValidator` base (`lib/src/class_suffix_validator.dart`), which takes `requiredSuffix`
and `baseClassName` as constructor params:

```dart
// use_bloc_suffix.dart:17-18
requiredSuffix: 'Bloc',
baseClassName: 'Bloc',
```

Because the logic is centralised, **reading the option in the base class makes all three rules
configurable at once.** This is the best effort-to-value ratio in the entire document.

Teams renaming Bloc→Feature, or using `...Store` / `...ViewModel` / `...Controller`, currently
cannot use these rules at all. another linter ships `name-pattern` (regex) for exactly this, defaulting to
`State$` / `Event$`.

```yaml
rules:
  use_bloc_suffix:
    suffix: Store           # or: name_pattern: '(Bloc|Store)$'
    ignore_private: true
```

Also applies to `use_sliver_prefix` (prefix `'Sliver'`) and the `endsWith('State')` heuristic at
`prefer_immutable_bloc_state.dart:96`.

Effort: ~3h for the base class + `use_sliver_prefix`.

### 2.3 Named numeric thresholds → `intOption`

Four constants, each already carrying a justifying comment. Pure mechanical wiring:

| Rule | Constant | File:line | Proposed key |
|------|----------|-----------|--------------|
| `prefer_container` | `_minSequence = 3` | `prefer_container.dart:97` | `min_sequence` |
| `prefer_class_destructuring` | `_minOccurrences = 3` | `prefer_class_destructuring.dart:39` | `min_occurrences` |
| `prefer_switch_with_enums` | `_threshold = 3` | `prefer_switch_with_enums.dart:32` | ⚠️ see below |
| `avoid_commented_out_code` | `_maxComments = 500` | `avoid_commented_out_code.dart:89` | ⚠️ see below |

⚠️ **`prefer_switch_with_enums._threshold` is reused for two different meanings** — comparison
count at `:85` and collection-element count at `:119`. Do not expose one key for both. Either split
into `min_comparisons` / `min_elements`, or leave it alone. This is precisely the another linter mistake
(`max-length` meaning three different units) that §1 exists to prevent.

⚠️ **`avoid_commented_out_code._maxComments = 500` is not a user-facing threshold** — it is an
internal performance bail-out that *silently stops analysing* a file past 500 comments (`:104`,
`:119`). Exposing it as config advertises a soft correctness limit. Better: document it, or make
the bail-out report a diagnostic rather than fail silently. **Recommend not exposing.**

another linter ships `min-sequence: 3` on `prefer-container` — identical default, confirming the value.

Effort: ~2h for the two safe ones.

### 2.4 `dispose_fields` / `dispose_provided_instances` → `cleanup_methods`

`lib/src/disposal_utils.dart:4` hardcodes, shared by both rules:

```dart
const cleanupMethods = ['dispose', 'close', 'cancel'];
```

Codebases with `release()`, `shutdown()`, `destroy()`, or a `Disposable` mixin cannot use these
rules. another linter's `dispose-class-fields` ships `methods: [dispose, close]` for this. Prime candidate for
the replace/append pair:

```yaml
rules:
  dispose_fields:
    additional_cleanup_methods: [release, shutdown]
```

Effort: ~2h (shared helper needs to accept the list; both rules pass theirs in).

---

## 3. Tier 2 — Broad-impact structural options

### 3.1 `package_names` — the `TypeChecker` monoculture

`packageName:` is hardcoded at **136 sites**, verified by grep:

| Package | Sites |
|---------|-------|
| `flutter` | 87 |
| `hooks_riverpod` | 12 |
| `flutter_riverpod` | 12 |
| `bloc` | 11 |
| `riverpod` | 8 |
| `flutter_bloc` | 6 |
| `flutter_hooks` | 5 |
| `equatable` | 3 |
| `sliver_tools`, `riverpod_annotation` | 1 each |

Consequence: any team using a **fork, a re-export, or a wrapper package** silently gets zero
diagnostics — the rule doesn't fire and there is no signal explaining why. This is a
"rules mysteriously don't work" class of bug, not a preference.

This is a large, cross-cutting change and should be a **global** config section rather than
per-rule. Consider deferring until someone actually reports it; noted here so the cost is known.

### 3.2 The `State` base-class cluster

**14 files** hardcode `TypeChecker.fromName('State', packageName: 'flutter')` (spread across
multiple lines — a single-line grep for `fromName('State'` misses it, which is how an earlier pass
under-counted this).

Affected: `dispose_fields`, `prefer_single_setstate`, `avoid_unnecessary_overrides_in_state`,
`avoid_unnecessary_setstate`, `use_sliver_prefix`, `avoid_empty_setstate`, `proper_super_calls`,
`avoid_unnecessary_stateful_widgets`, `avoid_recursive_widget_calls`, `always_remove_listener`,
`avoid_mounted_in_setstate`, `avoid_state_constructors`, `avoid_inherited_widget_in_initstate`.

Teams with a `BaseState<T>` intermediate class get partial coverage. A shared
`state_base_classes` option would fix all 14 at once — but only if routed through a shared helper
(there isn't one yet; this needs the extraction first).

Also flagged: **four rules define four different memberships for "State lifecycle methods."**
Reconciling those is a correctness cleanup that should precede any config work on them.

### 3.3 Universal `include` and `message`

Implement once in `ManyLintsRule`, applies to all 133 rules:

- **`include:`** — inverse of `exclude`; "only run this rule in `lib/features/**`". Architectural
  rules (layering, banned imports) are far more useful scoped than global.
- **`message:`** — append a project-specific sentence to the diagnostic
  ("Use our `AppSpacing` tokens instead"). Turns a generic lint into house style with one line
  of YAML. Cheap, high perceived value.

`exclude` is already applied at the reporter seam, so `include` slots into the same place.
`message` needs the reporter wrapper to rewrite the diagnostic message.

---

## 4. New config-centric rules (the banned-* family)

These rules **do nothing without config** — their entire value is user-supplied policy. They are
the most powerful rules another linter ships, and we have none of them.

### 4.1 ⚠️ Blocker: no map accessor

`RuleConfig` exposes only `boolOption` / `intOption` / `stringListOption`. The banned-* family needs
a **list of objects** (a banned entry plus its reason and path scope).

**Good news — verified empirically:** `RuleConfig._fromYaml` stores `options[name] = value.value`,
which **preserves nested `YamlMap`/`YamlList` structure**. I confirmed with a probe inside the
package:

```
runtimeType of .value => YamlList
first elem type       => YamlMap
deny                  => [package:http/.*] (YamlList)
```

So the data already survives parsing. **Only a typed accessor is missing** — no parser rewrite
needed. This is a much smaller change than it first appears.

**Prerequisite task:** add `List<Map<String, Object?>> entriesOption(String key)` to `RuleConfig`,
normalising `YamlMap`→`Map` and `YamlList`→`List<String>`, and returning `[]` on any malformed
shape (never throwing — see the cookbook's "malformed config must degrade" rule, which matters
doubly here because we **cannot** report config errors to the user).

### 4.2 Proposed API — flatter than the alternative

A third-party schema, for reference:

```yaml
linter:
  rules:
    - avoid-banned-imports:
        entries:
          - paths: ['lib/core/.*\.dart']
            deny: ['package:flutter_bloc/flutter_bloc.dart']
            message: 'State management not allowed in core.'
            severity: error
```

**Problems with it** (all observed across their catalogue):
- `entries` is overloaded across 12 rules to mean six unrelated shapes — a list of regexes, a list
  of class names, a list of 5-field objects, a discriminated union… you cannot infer the shape
  from the key.
- `message` in the avoid-banned-* family vs `description` in `banned-usage`, for the same concept.
- `paths` (list) vs `path` (single) for the same concept in adjacent rules.
- Regexes match as **substrings** by default, so `visibleForTesting` also matches
  `notVisibleForTesting`. They patch this with a docs note telling you to anchor with `^`/`$`.
- Windows path separators are pushed onto the user via a warning on nine separate pages.

**Our proposal** — name the key after its shape, one consistent field set, globs not regexes:

```yaml
rules:
  avoid_banned_imports:
    banned:
      - deny: ['package:flutter/material.dart']
        in: ['lib/domain/**', 'lib/data/**']   # optional; omit = everywhere
        message: 'Domain layer must not depend on Flutter.'
```

Deliberate divergences from another linter:

1. **`banned:` not `entries:`** — the key names the concept, and it stays unambiguous per rule.
2. **`in:` not `paths:`** — one spelling, always a list, always **globs**. We already use globs for
   `exclude` via analyzer's own `Glob`, so path semantics stay consistent across the whole config
   file, and `relativeIfContains` already normalises separators — **the Windows problem another linter pushes
   onto users disappears for free.**
3. **`message:` everywhere**, never `description`.
4. **Exact match by default.** `deny: ['package:http/http.dart']` matches that import and nothing
   else. Opt into patterns explicitly with a `deny_pattern:` key. another linter's implicit-substring-regex is
   the single most surprising thing in their API.
5. **No per-entry `severity`.** The analyzer's `diagnostics:` block already sets severity per rule,
   and per-entry severity would require one `LintCode` per entry. Deliberately out of scope.

### 4.3 The family, in priority order

| Rule | Bans | Why it matters |
|------|------|----------------|
| **`avoid_banned_imports`** | imports, scoped by path | **Highest value by far.** This is architecture enforcement — Clean Architecture layering, "no Flutter in domain", "no `dart:io` in shared". Nothing in the Dart ecosystem does this well outside another linter. Start here. |
| `avoid_banned_types` | type usages | Ban `DateTime.now()` in favour of an injected clock; ban a deprecated model. |
| `avoid_banned_names` | identifiers | Enforce vocabulary; ban `data`/`temp`/`manager`. Simplest to implement — a good pilot for `entriesOption`. |
| `avoid_banned_exports` | re-exports | Barrel-file hygiene. Niche; lowest priority. |
| `avoid_banned_annotations` | annotations, by path | Ban `@visibleForTesting` in production dirs. |

**Beyond another linter** — `banned_usage` (their most elaborate rule) covers member-level bans
(`DateTime.now`, `List.sort`, `MyEnum.value`). Worth considering as a *single* rule that subsumes
several of the above, rather than five near-duplicate rules. Their nested `type:` + `entries:`
union is clumsy; a flat `deny: ['DateTime.now', 'List.sort']` reads better and covers most real use.

### 4.4 Our own ideas, not in another linter

- **`avoid_banned_dependencies_in_layer`** — combine import bans with pubspec awareness.
  (Note: we cannot analyse pubspec — `PluginServer` never invokes `pubspecVisitor`. Import-level
  only.)
- **`require_import_alias`** — force `import 'package:x/x.dart' as x;` for configured packages.
  another linter has `prefer-named-imports`; ours would allow a required-alias *pattern*.
- **`banned_widget_in_path`** — a Flutter-flavoured `avoid_banned_types`: no `Scaffold` inside
  `lib/widgets/atoms/**`. Enforces design-system layering, which is a real and common need.

---

## 5. Tier 3 — Per-rule options worth adding

Grouped by the another linter precedent that validates them. Defaults preserve current behaviour.

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
| `prefer_class_destructuring` | `min_occurrences`, `ignored_types` | `3`, `[]` | exact match |
| `avoid_duplicate_bloc_event_handlers` | `additional_methods` | `[]` | exact match |
| `check_is_not_closed_after_async_gap` | `additional_methods` | `[]` | exact match |
| `avoid_hooks_outside_build` | `additional_methods` | `[]` | exact match |
| `avoid_misused_hooks` | `ignored_widgets` | `[]` | exact match |
| `prefer_immutable_bloc_state` | `name_pattern` | `State$` | exact match |
| `dispose_fields` | `ignore_blocs` | `false` | exact match |
| `avoid_unassigned_stream_subscriptions` | `ignored_instances` | `[]` | analogous |
| `prefer_spacing` / `use_gap` | `min_children`, `ignored_widgets` | — | our own |

**Deliberately NOT configurable.** Per the cookbook, "prefer a rule that is right by default over a
rule with knobs." These encode correctness, not preference, and an option would only let users hide
real bugs: `avoid_conditional_hooks`, `notifier_build`, `missing_provider_scope`,
`avoid_unsafe_collection_methods`, `use_ref_and_state_synchronously`, `proper_super_calls`,
`avoid_empty_setstate`, `list_all_equatable_fields`.

---

## 6. Bugs found during this research (unrelated to config)

Surfaced while auditing hardcoded values; **all verified by reading the source.** These deserve
their own fixes and should not be bundled into config work.

1. **`avoid_commented_out_code.dart:350`** — the code-prefix list contains `'override'` with no `@`
   and, unlike every neighbouring entry (`'import '`, `'static '`, `'State<'`), **no trailing
   space**. Any prose comment starting with the word "override" is misclassified as commented-out
   code. Should be `'@override'`.

2. **`prefer_container.dart:68-70`** — maps `IntrinsicHeight`→`'intrinsicHeight'`,
   `IntrinsicWidth`→`'intrinsicWidth'`, `LimitedBox`→`'limitedBox'`. **None of these are
   `Container` parameters.** The rule suggests a replacement that will not compile.

3. **`avoid_unnecessary_consumer_widgets.dart:44-56`** — omits `HookConsumerWidget` from its
   checkers, silently skipping those widgets.

4. **`async_builder_utils.dart:73-77`** — `isStableReference` is dead code; neither builder rule
   calls it.

---

## 7. Suggested sequencing

**Phase 1 — prove the pattern (~1 day).** §2.1 shorthands `classes`, §2.3 the two safe thresholds.
Small, self-contained, exercises the existing `stringListOption`/`intOption` paths. Establishes the
§1 naming vocabulary in real code and in the docs.

**Phase 2 — leverage (~2 days).** §2.2 suffix rules via `ClassSuffixValidator` (three rules, one
change), §2.4 `cleanup_methods` with the replace/append pair.

**Phase 3 — the big one (~1 week).** `entriesOption` accessor (§4.1), then `avoid_banned_imports`
as the flagship. Ship that alone before the rest of the family — it validates the API design under
real use, and it is the rule people will actually adopt the package for.

**Phase 4 — breadth.** Work down the §5 table; each is a few hours.

**Phase 5 — structural, only if demanded.** §3.1 `package_names`, §3.2 State cluster. Both need
shared-helper extraction first.

### Testing

Per the cookbook: `AnalysisRuleTest` **cannot** test configuration — there is no package root.
Every option needs a `PluginServer` test following `test/rule_config_test.dart`, and every negative
assertion must be paired with an **asymmetric positive** one. A test proving only silence cannot
distinguish "the option worked" from "the rule never fired" — this already produced one round of
vacuously-passing tests in this repo.

### Docs

Each configurable rule needs its `## Configuration` section extended with an options table
(name, type, default, description) per the cookbook template, always stating the default and the
`include:`-inheritance caveat.
