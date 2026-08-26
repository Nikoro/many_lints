# `dart analyze` silently skips the plugin on a large project (non-deterministic)

**Reported:** 2026-08-26 (found while migrating a Flutter app's bash quality gates to lints)
**Status:** OPEN
**Affects:** every rule — this is the plugin attachment path, not one rule's logic

## What happens

On a ~730-file Flutter app, the *same* command with the *same* configuration
alternates between reporting every finding and reporting none:

```
$ dart analyze --fatal-infos      # run 1
   1002 issues found.             # 113s

$ dart analyze --fatal-infos      # run 2, nothing changed
   No issues found!               # 18s
```

Exit code is 0 in the silent case. There is no error, no warning, and no notice
that the plugin was skipped — the run is indistinguishable from a genuinely
clean codebase.

The wall-clock time is the tell: a run that actually loads the plugin takes
~113s; a run that skips it finishes in ~18s. Verified repeatedly, alternating in
both directions on consecutive invocations.

## Why it matters

This is the worst failure mode a lint tool can have. A quality gate built on it
passes green while checking nothing, and the only symptom is an absence of
output. It cost most of a day's investigation here: I concluded three separate
times that the codebase was clean at `preset: opinionated`, when in fact the run
had silently skipped every rule. The real number was 1002.

A gate that randomly enforces nothing is worse than no gate, because it is
trusted. Until this is fixed, many_lints cannot back a CI check on a project of
this size.

## What it is NOT

Ruled out during diagnosis, each by direct A/B:

- **Not the argument form.** Reproduces with no argument at all (package root).
  Earlier I suspected `dart analyze <subdir>` specifically — that was wrong; the
  same root-level invocation gives both answers.
- **Not the cache alone.** A cold `~/.dartServer` run gave 1002 and a warm one
  gave 0 — but two consecutive warm runs also gave 1002 then 0. Cache state
  correlates loosely, it does not determine the outcome.
- **Not config location, plugin resolution, preset, or analyzer version.**
  Identical behaviour with `path:` and `version: ^1.1.0`, with the top-level
  `many_lints:` block and a standalone `many_lints.yaml`, with an explicit
  `rules:` entry and with `preset:`, and on analyzer 13.3.0 and 14.1.0.
- **Not reproducible at small scale.** A 2-file fixture is stable across 6
  consecutive runs (10 findings every time). The flakiness appears only on the
  large project, which points at a time- or size-dependent bail-out.

## Hypothesis

The analysis server appears to give up on the plugin when it does not attach
within some budget, and then proceeds without it rather than failing. The ~18s
vs ~113s split is consistent with "plugin never started" vs "plugin ran".

Whatever the mechanism, the fix has two parts and the second matters more than
the first:

1. Make attachment reliable (or retry it).
2. **Never proceed silently.** If the plugin is configured but not applied, that
   must surface as a diagnostic or a non-zero exit. A configured-but-inactive
   plugin is a build error, not a no-op. This alone would have turned a day into
   a minute.

## Environment

Dart 3.13.1, Flutter 3.47.1, macOS x64 (Intel), many_lints 1.1.0 (local
checkout via `path:`), project of 731 files under `lib/` plus 529 test files.

## Suggested acceptance test

Run `dart analyze` N times over a fixture large enough to be slow, and assert
the diagnostic count is identical on every run. A single-run test cannot catch
this; the bug is precisely that one run disagrees with the next.
