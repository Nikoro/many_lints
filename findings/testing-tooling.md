# Testing & Tooling

### [NOTE] [GOTCHA] Config-dependent rule behavior is testable via the PluginServer harness
**Area:** `test/rule_config_test.dart`
**Tags:** `#testing` `#tooling`
**Verified:** 2026-08-08

Per-rule configuration is fully testable end-to-end by driving a real `PluginServer`. So are fixes and assists, for the same reason: `analyzer_testing` exposes no API for any of the three (as of 0.3.4), but the plugin protocol answers `edit.getFixes` and `edit.getAssists`, which `test/fix_harness.dart` wraps. "No `analyzer_testing` API" never meant "untestable". Reuse the `_PluginAnalysisHarness` pattern from `test/plugin_diagnostics_config_test.dart`: `ResourceProviderMixin` + `createMockSdk` + `AnalysisSetAnalysisRootsParams`, then assert on the emitted `AnalysisError` codes. Remember `await pluginServer.waitForIdle()` in teardown, since 0.3.18+ analyzes asynchronously.

**Test-design caveat learned the hard way:** exclusion tests pass trivially if the fixture never triggers the rule in the first place. An initial attempt used `avoid_border_all`, whose `TypeChecker` requires real Flutter types that do not resolve under `createMockSdk` — so the rule reported nothing and every "excluded" assertion passed vacuously. Pick a pure-Dart rule for config fixtures, and always pair each negative test with an asymmetric positive one (e.g. `exclude: test/**` on a file in `lib/` must still report).

## Tooling

### [NOTE] `dart analyze <file>.yaml` validates analysis options — but only inside known sections
**Area:** `analysis_options.yaml`
**Tags:** `#tooling`
**Verified:** 2026-08-11 (Dart 3.12.2) — supersedes a 2026-08-08 note claiming no validation happens

Options validation does run when the file is named directly. `dart analyze analysis_options.yaml` and `dart analyze .` produce byte-identical output on the same bad config:

```
warning - analysis_options.yaml:2:3 - The option 'bogus_analyzer_key' isn't supported by 'analyzer'... - unsupported_option
warning - analysis_options.yaml:5:7 - 'not_a_real_lint_name' isn't a recognized lint rule... - undefined_lint
```

The real limit is *where* it looks: the validator only checks the interior of sections it recognizes. An unknown **top-level** key (`totally_unknown_top_level_key:`, or a typo like `analzyer:`) is accepted in silence — verified in the same run. So a misspelled section name disables that entire block of configuration with no diagnostic at all, which is the failure worth guarding against. Keep pairing config fixtures with a known-bad key *inside* a real section as a control.

---

### [GOTCHA] [CRITICAL] A regex over `LintCode(` silently captures a third of the rules
**Area:** `lib/src/rules/`, any script auditing rule metadata
**Tags:** `#gotcha` `#tooling`
**Verified:** 2026-08-09

**Symptom:** an audit comparing this package's rules against the official Dart SDK lint set reported a clean bill of health. The inventory behind it held **80 of 138** rules.

**Root cause:** `LintCode` arguments wrap across lines and use adjacent-string concatenation, so a single-line pattern like `LintCode\(\s*'([a-z0-9_]+)',\s*'(...)'` matches only the subset that happens to fit one line. Nothing errors — the missing 58 simply never appear.

**Workaround:** scan forward from `LintCode(` tracking paren depth, then pull quoted strings out of the balanced body:

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
    name, msg = parts[0], ' '.join(parts[1:])   # re-joins adjacent strings
```

**Assert the count before using the result:** extracted codes should equal the number of rule files (one `LintCode` per rule here). A short inventory produces a false-clean report, which is strictly worse than no report — it looks like evidence.

---

### [NOTE] [NOTE] The SDK publishes its lint catalogue as machine-readable JSON
**Area:** tooling / lint-set comparison
**Tags:** `#tooling` `#reference`
**Verified:** 2026-08-09

`https://raw.githubusercontent.com/dart-lang/sdk/main/pkg/linter/tool/machine/rules.json` is the source `dart.dev/tools/linter-rules` is generated from — 262 rules, each with `name`, `description`, `categories`, `state`, `incompatible`, `sets`, `fixStatus`, `details` (full markdown with BAD/GOOD samples) and `sinceDartSdk`.

**Do not scrape the HTML page.** Its markup changes, and it exposes neither `state`, `sets`, nor `details` reliably — the three fields that actually decide whether an SDK rule displaces one of ours.

Filter by `state` before comparing: only `stable` and `deprecated` rules can displace ours. A `removed` rule is not competition, and an `experimental` one is not a reason to deprecate a shipped rule.

`flutter_lints` (`packages/flutter_lints/lib/flutter.yaml` in `flutter/packages`) only *enables* SDK rules and defines none of its own, so it adds no names beyond `rules.json`.

---

### [GOTCHA] [CRITICAL] `dart analyze <dir>` drops plugin diagnostics on a cache hit
**Area:** verifying any rule against a real project; CI gates
**Tags:** `#gotcha` `#tooling` `#testing`
**Verified:** 2026-08-26 (Dart 3.13.1, analyzer 14.1.0, many_lints 1.1.0)

**Symptom:** the same `dart analyze --fatal-infos` alternates between reporting 1002 findings and `No issues found!` on an unchanged project. Exit code is 0 in the silent case. The only tell is wall-clock: ~113s when the plugin runs, ~18s when it does not.

**This is not a race, a timeout, or a size limit.** It is fully deterministic once the trigger is known, and it is not about scale — a twelve-file directory fails exactly like a 731-file `lib/`.

**The rule:** invoked with a **directory** (or no argument), `dart analyze` reports plugin diagnostics **only on the first run after the analysis-driver cache is invalidated**. Every run after that serves the file's cached result with the plugin's contribution missing. Invoked with **explicit file arguments**, the plugin runs every time.

| Invocation | Plugin diagnostics |
|---|---|
| `dart analyze path/to/file.dart` | every run |
| `dart analyze a.dart b.dart` | every run |
| `dart analyze lib/core/presentation` (12 files) | first run only |
| `dart analyze` (package root) | first run only |

**The control that proves it** — one probe file carrying an SDK diagnostic *and* two plugin diagnostics, three consecutive no-arg runs, nothing edited between them:

```
run 1: unused_local_variable   prefer_overriding_parent_equality   prefer_type_over_var
run 2: unused_local_variable
run 3: unused_local_variable
```

The SDK warning survives; both plugin diagnostics vanish after the first run. The file is still analyzed and its cache entry still read — only the plugin's output is absent from the cached result.

**What invalidates:** only a change to the *set of files*. Creating a file makes the next run report it; after that, another run is silent, `touch` is silent, and **editing the file's contents is still silent**. Deleting `~/.dartServer/.analysis-driver` resets it, which is what makes cold-vs-warm timing (93s vs 18s) look like an attachment race. The timing is cache population; it correlates without causing.

**Upstream, not ours.** Nothing in this package can fix it — the plugin is never asked. Needs a `dart-lang/sdk` issue against the analysis-driver caching path.

**Consequences for this repo's workflow, and they are the point:**

1. **Never verify a rule against a real project with a bare `dart analyze`.** Pass explicit files: `git ls-files -z '*.dart' | xargs -0 dart analyze --fatal-infos`. A 69 KB file list is one invocation, well under the 1 MB `ARG_MAX`.
2. **Never trust a clean run as evidence.** Drop in a probe file that *must* report, confirm it does, then remove it. Three separate investigations here concluded "the codebase is clean" when the run had silently skipped every rule.
3. **A bug report saying "the rule reports nothing in my project" is suspect until re-checked with explicit files.** `banned-usage-misses-top-level-functions.md` was filed on exactly this symptom; the rule worked fine and gave 14 findings once verified properly.

---

### [GOTCHA] [GOTCHA] The mock SDK's `Iterable` declares no `reduce`
**Area:** any rule/assist fixture calling a collection method
**Tags:** `#gotcha` `#testing`
**Verified:** 2026-08-26 (analyzer 14.1.0)

`createMockSdk` ships a deliberately minimal `Iterable`: `fold`, `where`, `map`, `firstWhere`, `expand` and friends are there, **`reduce` is not**.

A fixture calling `values.reduce(...)` therefore does not resolve. A **type**-matching rule or assist then declines — correctly, but for a reason unrelated to what is being tested. Through `FixHarness` the symptom is `Got: []` (no assists at all at that offset), which reads like a missing `registerAssist`.

Two workarounds, and the right one depends on how the producer matches:

- **Type-based** — declare the member in the fixture:
  ```dart
  extension <E> on Iterable<E> {
    E reduce(E Function(E value, E element) combine) => throw '';
  }
  ```
- **Name-based** — assert the resulting error and move on, as `test/avoid_unsafe_collection_methods_test.dart` does:
  ```dart
  [lint(42, 29), error(diag.undefinedMethod, 48, 6)]
  ```

Before concluding a type-based producer is broken, confirm every member the fixture calls actually resolves under the mock SDK.
