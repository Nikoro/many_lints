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
