# Testing & Tooling

### [NOTE] [GOTCHA] Config-dependent rule behavior is testable via the PluginServer harness
**Area:** `test/rule_config_test.dart`
**Tags:** `#testing` `#tooling`
**Verified:** 2026-08-08

Unlike fixes and assists — which have no `analyzer_testing` API as of 0.3.4 — per-rule configuration is fully testable end-to-end by driving a real `PluginServer`. Reuse the `_PluginAnalysisHarness` pattern from `test/plugin_diagnostics_config_test.dart`: `ResourceProviderMixin` + `createMockSdk` + `AnalysisSetAnalysisRootsParams`, then assert on the emitted `AnalysisError` codes. Remember `await pluginServer.waitForIdle()` in teardown, since 0.3.18+ analyzes asynchronously.

**Test-design caveat learned the hard way:** exclusion tests pass trivially if the fixture never triggers the rule in the first place. An initial attempt used `avoid_border_all`, whose `TypeChecker` requires real Flutter types that do not resolve under `createMockSdk` — so the rule reported nothing and every "excluded" assertion passed vacuously. Pick a pure-Dart rule for config fixtures, and always pair each negative test with an asymmetric positive one (e.g. `exclude: test/**` on a file in `lib/` must still report).

## Tooling

### [NOTE] [NOTE] `dart analyze <file>.yaml` does not validate analysis options
**Area:** `analysis_options.yaml`
**Tags:** `#tooling`
**Verified:** 2026-08-08

Running `dart analyze analysis_options.yaml` reports "No issues found" even for genuinely invalid options. Options validation only runs when the file is picked up as the options for an analyzed context root — i.e. `dart analyze .` on the containing project. When verifying options-file behavior, always analyze the project, and include a known-bad key as a control to confirm the validator actually ran.

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
