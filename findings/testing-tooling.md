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
