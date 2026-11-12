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

`https://raw.githubusercontent.com/dart-lang/sdk/main/pkg/linter/tool/machine/rules.json` is the source `dart.dev/tools/linter-rules` is generated from — 262 rules, each with `name`, `description`, `categories`, `state`, `incompatible`, `sets`, `fixStatus`, `details` (full markdown with BAD/GOOD samples) and `sinceDartSdk`. Re-checked 2026-11-12: the `3.14.0` tag has 264 rules, `sets` is empty in every entry (also on the 3.11.0 and 3.13.0 tags), and a rule in the internal `testing` state (`use_primary_constructors` in 3.14.0) is missing from the file although the SDK still runs it. Use the release tag, not `main`, when the report backs a release.

**Do not scrape the HTML page.** Its markup changes, and it exposes neither `state` nor `details` reliably — the fields that actually decide whether an SDK rule displaces one of ours.

Filter by `state` before comparing: only `stable` and `deprecated` rules can displace ours. A `removed` rule is not competition, and an `experimental` one is not a reason to deprecate a shipped rule.

`flutter_lints` (`packages/flutter_lints/lib/flutter.yaml` in `flutter/packages`) only *enables* SDK rules and defines none of its own, so it adds no names beyond `rules.json`.

---

### [GOTCHA] [CRITICAL] Dart 3.13.1–3.13.7 can exit before plugin diagnostics arrive (fixed in 3.14.0, but see #64023)
**Area:** verifying any rule against a real project; CI gates
**Tags:** `#gotcha` `#tooling` `#testing`
**Verified:** 2026-08-27 (Dart 3.13.1 revision `852b3e3608`; Dart 3.13.2 revision `60a57cd42d`; re-checked 2026-10-09 on Dart 3.13.5 revision `04bcd1036c`, Flutter 3.47.7); fixed release verified 2026-11-11 (Dart 3.14.0 revision `fa8c1270c3`, Flutter 3.50.0)

**Symptom:** the same `dart analyze --fatal-infos` alternates between reporting 1002 findings and `No issues found!` on an unchanged project. Exit code is 0 in the silent case. The only tell is wall-clock: ~113s when the plugin runs, ~18s when it does not.

**Cause:** this is a completion race, not a cache bug or a file-count limit. On Dart 3.13.x, `AnalyzeCommand` awaits `AnalysisServer.analysisFinished`, which is driven only by the analyzer's `server.status`, then immediately shuts the server down. Plugin work reports its lifecycle separately through `plugin.status`; the CLI does not wait for it. If the analyzer becomes idle first, pending plugin diagnostics die with the process.

A warm cache and a large real project make the race easier to lose: the first makes analyzer work faster, while the second makes plugin work slower. That produced two convincing but false diagnoses during investigation — “directory cache hits always fail” and “explicit argument lists fail above ~800 files.” A 4002-file synthetic fixture disproved both. File count and invocation shape affect timing, not correctness.

**Upstream fix, first shipped in Dart 3.14.0:** Dart SDK commit [`f0c0ab967e`](https://github.com/dart-lang/sdk/commit/f0c0ab967e9d3f85d73b3fcd13da29a0277daa01) (“[dartdev] Switch 'dart analyze' to use LSP instead of the legacy protocol”) switches `dart analyze` to LSP `workspaceAnalysisComplete()`. That handler waits for context rebuilds, analyzer-driver idle, plugin initialization, and finally `plugin.status == false`. SDK integration tests cover a plugin diagnostic even when the completion request is sent immediately after initialization. The commit is an ancestor of the `3.14.0` tag; the 3.13 stable branch diverged before it, so every 3.13 release through 3.13.7 still awaits `analysisFinished`. Evidence for 3.14.0: its [`analyze.dart`](https://github.com/dart-lang/sdk/blob/3.14.0/pkg/dartdev/lib/src/commands/analyze.dart) creates an `LspAnalysisServer` and awaits `workspaceAnalysisComplete()` before shutdown; the shipped `dartdev_aot.dart.snapshot` contains `dart/workspace/analysis/complete`; and on a 2420-file Flutter app a single bare `dart analyze --fatal-infos`, with no batching, reported its canary in 3 of 3 runs (on 3.13 the same app lost the canary above ~850 files). `flutter analyze` on Flutter 3.50.0 waits on the same request.

**Not the end of it:** 3.14.0 fixes this early exit, not every lost diagnostic. See the next finding (dart-lang/sdk#64023). The 2026-11-11 conclusion that a single `dart analyze` needs no canary on 3.14.0 was wrong.

**Consequences for this repo's workflow:**

1. On Dart 3.14.0 and later, no batching is needed for this race. Follow the next finding: one target, no inheriting nested packages, and a canary.
2. On Dart 3.13.1 through 3.13.7, batch explicit files of one package well below the observed slow-project cliff (`git ls-files -z '*.dart' | xargs -0 -n 400 dart analyze --fatal-infos`) **and** keep a canary: a file that must produce a plugin diagnostic, proven alone, included in every batch, failing that batch when absent. Batching only narrows the race; the canary is the only deterministic guard on an affected SDK.
3. **Do not diagnose a silent plugin from file count, cache state, or command shape.** Check the SDK version first.

---

### [GOTCHA] [CRITICAL] Dart 3.14 still drops plugin diagnostics when several plugin isolates run (dart-lang/sdk#64023)
**Area:** verifying any rule against a real project; CI gates
**Tags:** `#gotcha` `#tooling` `#testing`
**Verified:** 2026-11-12 (Dart 3.14.0, Flutter 3.50.0; source checked at the `3.14.0` tag and on `main`)

**Symptom:** on Dart 3.14.0, `dart analyze` reports every core lint but some or all Many Lints findings are missing, and the exit code reflects only what was reported. In Songbook, `dart analyze --fatal-infos lib test integration_test backend/tests/trials scripts/quality/architecture` lost every Many Lints finding, a canary included, in 3 of 3 runs; `dart analyze --fatal-infos .` reported all of them in 3 of 3. In a two-file package, `dart analyze lib test` lost one Many Lints finding in 2 of 13 runs while both SDK `unused_import` warnings always appeared; `dart analyze .` lost none in 14.

**Cause:** the 3.14 `workspaceAnalysisComplete` handler waits for `server.notificationManager.pluginStatusAnalyzing` to become false. That is a single shared `bool` (`pkg/analysis_server/lib/src/plugin/notification_manager.dart`, line 81), but the server starts one plugin isolate per context root that has plugins. When one isolate goes idle the flag drops and the CLI can finish before another isolate's diagnostics arrive. Several targets mean several context roots; so does a nested directory with its own `pubspec.yaml` and no `analysis_options.yaml`, which inherits the parent's `plugins:` (verified on a temp fixture: `AnalysisContextCollection` makes it its own context root and the plugin reports there). Upstream: [#64023](https://github.com/dart-lang/sdk/issues/64023) (open, filed for 3.12 / plugin 0.3.20, flag unchanged in 3.14.0). Related: [#62710](https://github.com/dart-lang/sdk/issues/62710) (closed, said fixed for 3.14) and [#62690](https://github.com/dart-lang/sdk/issues/62690) (open). The rules run correctly; a plugin cannot fix the server's status aggregation from inside its rules.

**Consequences:**

1. Run `dart analyze` with exactly one target, the package or workspace root, and exclude what should not be analyzed in `analysis_options.yaml`.
2. Give every nested package its own `analysis_options.yaml` without `plugins:` so it does not get a plugin isolate.
3. Keep a canary in CI and fail when it is missing. Even with one target, a temp fixture with one plugin-enabled context root next to two plugin-free ones lost every Many Lints diagnostic in 1 of 10 runs, so the canary is still the only proof. Details and run counts: `TODO/plugin-silently-skipped-on-large-projects.md`.

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
- **Name-based** — assert the resulting error with `undefinedName` from `test/many_lints_rule_test_base.dart` and move on, as `test/avoid_unsafe_collection_methods_test.dart` does:
  ```dart
  [lint(42, 29), undefinedName(48, 6)]
  ```
  Do not write `error(diag.undefinedMethod, ...)`: analyzer 14.6 replaced `undefined_method`, `undefined_getter`, `undefined_function`, `undefined_identifier` and `undefined_prefixed_name` with read/write variants such as `undefined_instance_member_read`, and the package's range spans both (14.5 on Dart 3.11, 14.7 on Dart 3.13+). `undefinedName` matches either spelling.

Before concluding a type-based producer is broken, confirm every member the fixture calls actually resolves under the mock SDK.
