# Plugin diagnostic aggregation across context roots

Upstream task: [dart-lang/sdk#64023](https://github.com/dart-lang/sdk/issues/64023).
Close only after a stable SDK fix passes repeated multi-context runs with a proven
canary. The plugin's rules cannot repair the server's completion aggregation.

The Dart 3.14.0 completion fix waits for the server's
`notificationManager.pluginStatusAnalyzing` to become false. That is one shared
`bool` (`pkg/analysis_server/lib/src/plugin/notification_manager.dart`, line 81,
unchanged at the `3.14.0` tag and on `main`), while the server starts one plugin
isolate per context root that has plugins. When one isolate reports idle, the
flag goes false and `dart analyze` can finish while another isolate's
diagnostics are still on the way. Upstream issue
[#64023](https://github.com/dart-lang/sdk/issues/64023) (open) was filed for
Dart 3.12 and `analysis_server_plugin` 0.3.20; the flag is the same in 3.14.0,
so it still applies. Related:
[#62710](https://github.com/dart-lang/sdk/issues/62710) (closed; plugin rules
missing when `dart analyze` targets a folder, said fixed for 3.14) and
[#62690](https://github.com/dart-lang/sdk/issues/62690) (open; plugins not
working when the base folder has no `analysis_options.yaml`).

The rules run correctly. The loss is in the server's status aggregation, and a
plugin cannot fix it from inside its rules.

## Reproduction evidence on Dart 3.14.0

- Songbook, several targets (several context roots):
  `dart analyze --fatal-infos lib test integration_test backend/tests/trials scripts/quality/architecture`
  lost every Many Lints finding, a canary included, in 3 of 3 runs, while core
  lints were reported. `dart analyze --fatal-infos .` with probes in `lib/`,
  `test/` and `backend/tests/trials/` reported all of them in 3 of 3 runs.
- Two-file package (`lib/a.dart`, `test/b.dart`, each with an unused import
  and a banned name): `dart analyze lib test` always reported both SDK
  `unused_import` warnings but lost one Many Lints finding in 2 of 13 runs.
  `dart analyze .` lost none in 14 runs.
- Nested package that inherits `plugins:` (temp fixture, Dart 3.14.0 on
  macOS arm64, this package at 1.3.0 by `path:`: root package with
  `plugins: many_lints` and a `class Manager {}` probe banned by
  `avoid_banned_names`; `nested/` with its own `pubspec.yaml`, a
  `many_lints.yaml` and the same probe, but no `analysis_options.yaml`).
  `AnalysisContextCollection` lists `nested/` as its own context root whose
  options file is the root `analysis_options.yaml`. A single `dart analyze .`
  reported the nested probe in 12 of 13 runs (once twice in the same run), so
  the plugin runs there. The nested probe went missing in 1 run and the root
  probe in another. After giving `nested/` an `analysis_options.yaml` without
  `plugins:`, its probe was reported in 0 of 10 runs.
- Two side observations from the same fixtures, not yet explained:
  - A sibling package with its own options file without `plugins:` still got
    Many Lints diagnostics in some runs: 6 of 13 next to the inheriting
    `nested/`, 4 of 10 once `nested/` had its own options, and 7 of 10 in a
    fresh fixture with two such packages, where only the alphabetically last
    one was ever reported.
  - With one plugin-enabled context root next to two plugin-free ones, 1 run of
    10 reported no Many Lints diagnostic at all. The fresh two-sibling fixture
    reported the root probe in 10 of 10 runs, and a control package with a
    single context root in 15 of 15.

  So one target and no inheriting nested packages make the loss rare, not
  impossible; the canary stays required.

## Mitigation until #64023 is fixed

1. Run `dart analyze` with exactly one target, the package or workspace root.
   Exclude what should not be analyzed with `analyzer: exclude:` in
   `analysis_options.yaml` instead of listing folders.
2. Avoid nested packages that inherit `plugins:`. Give each nested package its
   own `analysis_options.yaml` without `plugins:` (the workaround from #64023).
3. In CI, keep a canary: a file with a deliberately reported Many Lints
   diagnostic, proven alone first, and fail the job when it is missing.


## Earlier SDKs

Dart 3.13.1 through 3.13.7 can terminate before plugin analysis becomes idle.
Dart 3.14.0 contains [the completion wait fix](https://github.com/dart-lang/sdk/commit/f0c0ab967e9d3f85d73b3fcd13da29a0277daa01),
but that does not fix multi-isolate aggregation. On 3.13, batch explicit files
with a proven canary in every batch. Synthetic file-count or cache hypotheses do
not establish the cause: large synthetic packages did not reproduce the field
reports. Always reproduce on the affected package before drawing conclusions.

A canary must be proven alone first. `deny: ['manager']` does not match
`CanaryManager`: deny entries match exact, case-sensitive names.
