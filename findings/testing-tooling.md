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

### [GOTCHA] [CRITICAL] Dart 3.13.1 can exit before plugin diagnostics arrive
**Area:** verifying any rule against a real project; CI gates
**Tags:** `#gotcha` `#tooling` `#testing`
**Verified:** 2026-08-27 (Dart 3.13.1 revision `852b3e3608`)

**Symptom:** the same `dart analyze --fatal-infos` alternates between reporting 1002 findings and `No issues found!` on an unchanged project. Exit code is 0 in the silent case. The only tell is wall-clock: ~113s when the plugin runs, ~18s when it does not.

**Cause:** this is a completion race, not a cache bug or a file-count limit. Dart 3.13.1's `AnalyzeCommand` awaits `AnalysisServer.analysisFinished`, which is driven only by the analyzer's `server.status`, then immediately shuts the server down. Plugin work reports its lifecycle separately through `plugin.status`; the CLI does not wait for it. If the analyzer becomes idle first, pending plugin diagnostics die with the process.

A warm cache and a large real project make the race easier to lose: the first makes analyzer work faster, while the second makes plugin work slower. That produced two convincing but false diagnoses during investigation — “directory cache hits always fail” and “explicit argument lists fail above ~800 files.” A 4002-file synthetic fixture disproved both. File count and invocation shape affect timing, not correctness.

**Upstream fix:** Dart SDK commit `f0c0ab967e` switches `dart analyze` to LSP `workspaceAnalysisComplete()`. That handler waits for context rebuilds, analyzer-driver idle, plugin initialization, and finally `plugin.status == false`. Integration tests cover a plugin diagnostic even when the completion request is sent immediately after initialization. The commit is on SDK `main`, but is not part of Dart 3.13.1; verify the first released fixed version before documenting one.

**Consequences for this repo's workflow:**

1. On Dart 3.13.1, batch explicit files well below the observed slow-project cliff: `git ls-files -z '*.dart' | xargs -0 -n 400 dart analyze --fatal-infos`. Batching reduces the race window but is not a correctness guarantee.
2. **Never trust a clean run without a canary.** Keep a file that must produce a plugin diagnostic, prove it fires alone, include it in every batch, and fail that batch when it is absent. Checking the canary once does not protect later invocations. This is the only deterministic consumer-side guard on an affected SDK.
3. **Do not diagnose from file count, cache state, or command shape.** Re-check with the canary and inspect the SDK version. The same race can make any of those correlations look absolute on one project and disappear on another.
4. Once using an SDK that contains `f0c0ab967e`, validate both a deliberately slow plugin and an immediate completion request before removing the canary.

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
