---
name: sync-official-lints
description: Compares the official Dart SDK linter rules against this package's rules to find overlaps, then drives the deprecate → remove lifecycle so many_lints never duplicates a rule the SDK already ships. Use when the user wants to check for duplicate/overlapping lints, sync with dart.dev/tools/linter-rules, or deprecate and remove a rule.
---

You are auditing **many_lints** against the official Dart SDK linter rules and, where they overlap, retiring our rule through a two-stage lifecycle: **deprecate first, remove in a later major/minor version**.

The user may pass:
- **No argument** — full audit of every rule in the package.
- **A rule name** (`avoid_returning_widgets`) — audit just that rule.
- **A category** (`--category widget-best-practices`) — audit one docs category.
- **`--deprecate <rule> [--replaced-by <sdk_rule>]`** — skip the audit, run only Stage A on that rule.
- **`--remove <rule>`** — skip the audit, run only Stage B on that rule.
- **`--report-only`** — produce the report, change nothing.

---

## Step 1: Fetch the official rule set

**Do not scrape `https://dart.dev/tools/linter-rules`.** That page is generated
HTML and its markup changes. The same data is published machine-readable and is
the source the docs page itself is built from:

```bash
curl -fsSL https://raw.githubusercontent.com/dart-lang/sdk/main/pkg/linter/tool/machine/rules.json \
  -o /tmp/dart_lint_rules.json
```

Each entry has these fields (verified 2026-08-09, 262 rules):

| Field | Meaning |
|---|---|
| `name` | snake_case rule name |
| `description` | one-line summary |
| `categories` | e.g. `["style"]`, `["errorProne"]`, `["flutter"]` |
| `state` | `stable` \| `experimental` \| `deprecated` \| `removed` |
| `incompatible` | rules that conflict with it |
| `sets` | which of `core` / `recommended` / `flutter` include it |
| `fixStatus` | `hasFix` / `noFix` / … |
| `details` | full markdown docs, including `**BAD:**` / `**GOOD:**` samples |
| `sinceDartSdk` | SDK version that introduced it |

If the fetch fails (offline, moved file), fall back in this order and say which
source you used in the report:
1. `https://raw.githubusercontent.com/dart-lang/sdk/stable/pkg/linter/tool/machine/rules.json`
2. WebFetch on `https://dart.dev/tools/linter-rules` (degraded: no `details`, no
   `sets`, so semantic matching in Step 3 will be weaker — flag this).

**Filter before comparing.** Only rules with `state` of `stable` or
`deprecated` are candidates for displacing one of ours. A rule the SDK has
`removed` is not competition, and an `experimental` SDK rule is not a reason to
deprecate a shipped rule of ours — note it as "watch" instead.

Also check the **Flutter** lint set, which lives in a different package and is
not in `rules.json`:

```bash
curl -fsSL https://raw.githubusercontent.com/flutter/packages/main/packages/flutter_lints/lib/flutter.yaml
```

As of 2026-08-09 this file only *enables* SDK rules and defines none of its own,
so it adds no collisions beyond what `rules.json` already covers. Check it
anyway — that could change — but do not expect new rule names from it. Its real
use is the reverse check below: rules a Flutter user already has switched on.

## Step 2: Inventory our rules

1. List rule sources: `ls lib/src/rules/*.dart`.
2. For each, read the `LintCode` — its `name`, `problemMessage`, and
   `correctionMessage` — plus the class doc comment. That triple is what you
   compare against the SDK's `description` + `details`.
3. Note which rules already carry a `RuleState` (see Step 5) so an
   already-deprecated rule is not re-reported as a new finding.
4. Cross-reference the docs page in
   `docs/src/content/docs/docs/rules/<category>/<rule-name>.md` for the
   human-facing rationale — the "Why use this rule" section often states the
   intent more clearly than the code does.

**Extract with a brace-matching parser, not a regex.** `LintCode` arguments wrap
across lines and use adjacent-string concatenation, so a single-line pattern
like `LintCode\(\s*'([a-z0-9_]+)',\s*'(...)'` silently captures only the
subset that happens to fit one line — on the 2026-08-09 run that was 80 of 138
rules, with no error to signal the other 58 were missing. Scan forward from
`LintCode(` tracking paren depth, then pull the quoted strings out of the
balanced body:

```python
for m in re.finditer(r"LintCode\(", src):
    i = m.end(); depth = 1; j = i
    while j < len(src) and depth:
        if src[j] == '(': depth += 1
        elif src[j] == ')': depth -= 1
        j += 1
    body = src[i:j-1]
    pre = body.split('correctionMessage:')[0]
    parts = re.findall(r"'((?:[^'\\]|\\.)*)'", pre, re.S)
    name, msg = parts[0], ' '.join(parts[1:])   # msg re-joins adjacent strings
```

**Assert the count before comparing.** The number of extracted codes should
equal the number of rule files (one `LintCode` per rule in this package). If it
does not, stop and fix the extraction — a short inventory produces a
false-clean report, which is worse than no report.

Read the rule sources in batches with parallel tool calls; do not read all 138
files one at a time. Reserve full reads for the rules that reach a `DUPLICATE`
or `SUPERSET` verdict in Step 3 — those verdicts must be backed by the visitor
logic, never by the message text alone.

## Step 3: Classify each overlap

For every one of our rules, decide which bucket it falls in. Run **both** passes
— name matching alone misses the majority of real duplicates, because the SDK
and this package frequently name the same idea differently.

**Pass 1 — exact name collision.** Our name is byte-identical to an SDK rule
name. This is the severe case: both rules fire on the same code and the user
sees two diagnostics. Always a `DUPLICATE`.

**Pass 2 — semantic overlap.** Compare our `problemMessage` and class doc
against the SDK `description` and `details` (including its BAD/GOOD samples).
Ask: *would these two rules fire on the same source line?*

Assign exactly one verdict:

| Verdict | Meaning | Action |
|---|---|---|
| `DUPLICATE` | SDK rule fires on the same code, same intent, no extra coverage from ours | Stage A — deprecate |
| `SUPERSET` | The SDK rule covers everything ours does **and more** | Stage A — deprecate |
| `SUBSET` | Ours catches cases the SDK rule misses | Keep. Document the difference in our docs page |
| `ADJACENT` | Related area, genuinely different trigger | Keep. No action |
| `WATCH` | Overlapping SDK rule exists but is `experimental` | Keep. Record for the next run |
| `UNIQUE` | No SDK counterpart | Keep. No action |

For `SUBSET`, be concrete about what ours adds — a one-line justification the
user can paste into the docs. "Ours also handles X" is only useful if X is
named. If you cannot name the delta, the verdict is `DUPLICATE`, not `SUBSET`.

**Names lie in both directions — read the visitor before deciding.** Cases seen
on the first real run:

- **Near-identical names, disjoint triggers.** `avoid_generics_shadowing` and
  SDK `avoid_shadowing_type_parameters` sound like the same rule; ours flags a
  type parameter shadowing a top-level declaration in the same file, the SDK's
  flags one shadowing an *enclosing type parameter*. Verdict `SUBSET`, not
  `DUPLICATE`. Say so in the report — the names invite the wrong conclusion.
- **Different names, same trigger.** `avoid_collection_methods_with_unrelated_types`
  vs SDK `collection_methods_unrelated_type`. Only the `details` method list
  settles it.
- **Opposite advice on the same code.** `prefer_abstract_final_static_class`
  says mark the static-only class `abstract final`; SDK
  `avoid_classes_with_only_static_members` says delete the class and use
  top-level members. That is not an overlap to deprecate — it is a conflict to
  document, so users do not enable both. Give it its own line in the report.
- **A rule may quote the SDK in its own doc comment.** Grep the class docs for
  the SDK rule name; several of ours already state the relationship
  explicitly, which is the strongest possible evidence either way.

Before assigning `DUPLICATE` or `SUPERSET`, read the rule's visitor in full and
the SDK rule's `details` in full. A verdict resting only on the one-line
`description` is not verified.

**Bias toward keeping.** Deprecating a rule is user-visible churn. Only propose
Stage A when the overlap is clear enough that you can quote the SDK
`description` and our `problemMessage` side by side and have them read as the
same rule. When it is a judgement call, report it and let the user decide —
never deprecate on your own initiative.

Also do the reverse check: list `stable` SDK rules in the `flutter` category
that we have no counterpart for, in a short "gaps" section. Frame it as
**coverage information, not a backlog** — those rules are mostly already
enabled via `flutter_lints`, so writing our own versions would manufacture
exactly the duplication this skill exists to prevent. Say that in the report so
the list is not mistaken for a work queue.

## Step 4: Write the report

Write `LINT_SYNC_REPORT.md` at the repo root:

```markdown
# Official Lint Sync Report

Generated: <date> · Source: `pkg/linter/tool/machine/rules.json` @ <commit or "main">
SDK rules compared: <n> stable, <n> deprecated · many_lints rules: <n>

## Summary

| Verdict | Count |
|---|---|
| DUPLICATE | n |
| SUPERSET | n |
| SUBSET | n |
| WATCH | n |
| UNIQUE | n |

## Action required

### DUPLICATE — recommend deprecating

- [ ] **`our_rule`** → SDK **`sdk_rule`** (`stable`, since Dart 3.x, in `recommended`)
  - Ours: "<problemMessage>"
  - SDK: "<description>"
  - Rationale: <one or two sentences>

### SUPERSET — recommend deprecating
…

## Keep, with a documented difference

### SUBSET
- **`our_rule`** vs SDK `sdk_rule` — ours additionally flags <specific case>.

## Watch (SDK rule still experimental)
…

## Gaps — Flutter-category SDK rules we do not cover
…
```

Use checkboxes on the actionable items so the report survives across sessions:
on a later run, re-read an existing `LINT_SYNC_REPORT.md` first and preserve
already-ticked entries rather than regenerating from scratch.

If `--report-only`, stop here.

## Step 5: Present findings and get approval

Show the user the `DUPLICATE` and `SUPERSET` lists and ask which rules to act
on, using the input mechanism available in the current environment. **Never
deprecate or remove a rule without explicit approval** — this is a published
package and both stages are breaking for someone.

Ask separately about Stage A (deprecate now) and Stage B (remove rules
deprecated in an earlier release), since they usually belong to different
version bumps.

---

## Stage A — Deprecate a rule

A deprecated rule **still runs and still reports**. It only gains a marker and
a migration note. This is the entire point of the two-stage lifecycle: users get
a release where their config keeps working while they migrate.

The analyzer has a first-class mechanism for this — do not invent one.
`AnalysisRule` accepts a `state:` parameter of type `RuleState`
(`package:analyzer/analysis_rule/rule_state.dart`), and our `ManyLintsRule` base
class already forwards it via `super.state`. Verified against analyzer 14.1.0:

```dart
import 'package:analyzer/analysis_rule/rule_state.dart';

class AvoidSomething extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_something',
    'DEPRECATED: use the SDK rule `sdk_rule` instead. <original message>',
    correctionMessage:
        'Remove `avoid_something` from analysis_options.yaml and enable '
        '`sdk_rule` under `linter: rules:`.',
  );

  AvoidSomething()
    : super(
        name: 'avoid_something',
        description: 'DEPRECATED — replaced by the SDK rule `sdk_rule`.',
        state: RuleState.deprecated(replacedBy: 'sdk_rule'),
      );
```

`RuleState.deprecated` takes `since` (a `pub_semver` `Version`) and `replacedBy`
(a `String` rule name). Leave `since` unset: it means a **Dart language
version**, not our package version, and setting it would pull `pub_semver` in as
a new direct dependency for no benefit. Our package version belongs in the
CHANGELOG and the docs aside instead.

Do **not** use `RuleState.removed`: it is `@Deprecated` in the analyzer in
favour of `RemovedAnalysisRule` (see Stage B).

Checklist for each rule being deprecated:

1. **Rule source** — add `state: RuleState.deprecated(replacedBy: '<sdk_rule>')`
   and prefix `problemMessage` with `DEPRECATED:`, pointing at the replacement.
2. **Keep the rule registered** in `lib/many_lints.dart`. It must keep firing.
3. **Keep the fix registered** if it has one. A user still on the rule should
   still get the fix.
4. **Tests** — do not delete them. Update expected messages to match the new
   `problemMessage`. Add one assertion that the rule's `state.isDeprecated` is
   `true`, so the marker cannot silently regress.
5. **Docs page** — `docs/src/content/docs/docs/rules/<category>/<rule-name>.md`:
   - Add a Starlight aside directly under the badges:
     ```mdx
     :::caution[Deprecated in v<version>]
     Replaced by the official Dart rule
     [`sdk_rule`](https://dart.dev/tools/linter-rules/sdk_rule).
     This rule will be removed in v<next-major>. Enable the SDK rule under
     `linter: rules:` in `analysis_options.yaml` and drop this one.
     :::
     ```
   - Add a `Deprecated` badge to the frontmatter `sidebar.badge`
     (`text: "Deprecated"`, `variant: "caution"`).
6. **README** — decrement the category count in the rules table if the rule is
   being counted there.
7. **CHANGELOG** — a `### Deprecated` section naming the rule, the SDK
   replacement, and the version in which it will be removed.

Deprecations are a **minor** bump, never a patch.

## Stage B — Remove a deprecated rule

Only remove a rule that shipped as deprecated in at least one prior release.
Verify this in the CHANGELOG before touching anything; if the rule was never
released deprecated, do Stage A instead and tell the user why.

The naive removal — deleting the rule and its registration — is hostile: every
user with that rule in their `analysis_options.yaml` gets an
"unrecognized rule" warning with no explanation. The analyzer provides a
tombstone for exactly this, `RemovedAnalysisRule`, which registers the name with
no diagnostic codes so the config keeps resolving:

```dart
RemovedAnalysisRule(
  name: 'avoid_something',
  description: 'Removed in v<version>. Use the SDK rule `sdk_rule`.',
  replacedBy: 'sdk_rule',
)
```

Checklist for each rule being removed:

1. **Delete** `lib/src/rules/<rule>.dart`, plus its fix in `lib/src/fixes/` and
   any assist that exists only for it.
2. **Registration** in `lib/many_lints.dart` — remove the imports and the
   `_registerWarningRule` / `registerFixForRule` calls, and replace them with a
   `RemovedAnalysisRule` tombstone as above. Keep tombstones grouped together at
   the end of the registration block under a `// Removed rules` comment.
3. **Delete** `test/<rule>_test.dart` and any fix test.
4. **Delete** `example/lib/<rule>_example.dart`.
5. **Docs** — delete the rule page and add a redirect in
   `docs/astro.config.mjs` pointing the old path at the SDK rule's page, so
   existing links do not 404.
6. **README** — decrement the category count.
7. **CHANGELOG** — a `### Removed` section under a **breaking** heading.
8. Grep for stragglers: `rg '<rule_name>' --hidden -g '!.git'` should return
   only the CHANGELOG, the tombstone, and the redirect.

Removals are **breaking**: a major bump, or a minor bump while the package is
pre-1.0 — match whatever `/release` infers from a `!` commit.

## Step 6: Verify

Run the same gates `/release` runs, and do not report success until they pass:

```bash
dart analyze                                    # zero issues
dart test                                       # all green
dart format --output=none --set-exit-if-changed .
cd docs && bun run build                        # docs must still build
```

If the docs build fails on a deleted page, the redirect in Step B5 is missing or
wrong.

## Step 7: Report back

Summarize:
- Which rules were deprecated, and their SDK replacements.
- Which rules were removed, and the tombstones left behind.
- Which overlaps were found but deliberately kept, and why.
- The version bump the changes imply, so the user can run `/release`.

Do not commit. Leave that to `/commit`.

---

## Rules

- **Never scrape the HTML docs page when `rules.json` is reachable.** The JSON
  carries `state`, `sets`, and `details`, none of which the rendered page
  exposes reliably.
- **Never deprecate or remove without explicit user approval**, even when the
  overlap is unambiguous.
- **Never skip Stage A.** A rule goes deprecated-then-removed across two
  releases. Removing a live rule in one step breaks configs silently.
- **A deprecated rule keeps working.** If it stops reporting, that is a bug, not
  a deprecation.
- **Only `stable` and `deprecated` SDK rules can displace ours.** Experimental
  SDK rules get the `WATCH` verdict and nothing more.
- **Name a concrete delta or call it a duplicate.** `SUBSET` without a specific
  extra case it catches is wishful thinking.
- **Never compare against a partial inventory.** Assert extracted-code count ==
  rule-file count before classifying. A regex that quietly drops two thirds of
  the rules yields a clean-looking report that is simply wrong.
- **Verdicts of `DUPLICATE`/`SUPERSET` require reading the visitor**, not just
  the `problemMessage`. Names both over- and under-state the real overlap.
- **Do not touch rules the user did not approve**, even if you spot an unrelated
  problem while editing. Report it instead.
