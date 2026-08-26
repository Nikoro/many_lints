# `dart analyze` drops plugin diagnostics on a cache hit, and again past ~800 file arguments

**Reported:** 2026-08-26 (found while migrating a Flutter app's bash quality gates to lints)
**Status:** OPEN — two independent triggers, both upstream (see Diagnosis 2026-08-26 and Correction 2026-08-27)
**Affects:** every rule — an upstream analysis-server cache bug, not this package

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

## Diagnosis 2026-08-26 — it is the analysis-driver cache, not a timeout

The bug is real and worse than "non-deterministic": it is **fully
deterministic** once you know the trigger, and it is not size-dependent at all.
The title and the timeout hypothesis above are both wrong.

### The rule

`dart analyze` invoked with a **directory** (or with no argument) reports plugin
diagnostics **only on the first run after the analysis-driver cache is
invalidated**. Every subsequent run serves that file's result from
`~/.dartServer/.analysis-driver` with the plugin diagnostics **missing**.

Invoked with **explicit file arguments**, the plugin runs every time.

| Invocation | Plugin diagnostics |
|---|---|
| `dart analyze path/to/file.dart` | every run |
| `dart analyze a.dart b.dart` | every run |
| `dart analyze lib/core/presentation` (a 12-file dir) | first run only |
| `dart analyze lib` | first run only |
| `dart analyze` (package root) | first run only |

Scale is irrelevant — a twelve-file directory fails exactly like the 731-file
`lib/`. What separates the two columns is directory-vs-file argument, not size.

### The control that proves it

One probe file carrying an SDK diagnostic *and* two plugin diagnostics, three
consecutive no-arg runs, nothing edited between them:

```
run 1: unused_local_variable   prefer_overriding_parent_equality   prefer_type_over_var
run 2: unused_local_variable
run 3: unused_local_variable
```

The SDK warning survives every run; both plugin diagnostics disappear after the
first. So the file is still being analyzed and its cache entry is still being
read — only the plugin's contribution is absent. Plugin output is not part of
the cached result, and nothing re-runs the plugin on a cache hit.

### What invalidates (and what does not)

Only a change to the **set of files** resets it. Creating the probe file makes
the next run report it; after that:

- another run, nothing changed → silent
- `touch` (mtime only) → silent
- **editing the file's contents** → still silent

That last one is the surprising part and rules out content hashing as the key.
Deleting `~/.dartServer/.analysis-driver` resets it, which is what made the
earlier cold-vs-warm timing (93s vs 18s) look like a plugin-attachment race. The
timing is just cache population; it correlates with the symptom without causing
it.

### Why the original investigation looked random

Every no-arg run that followed a file edit or a fresh checkout reported
findings, and every repeat run reported none. Alternating between "1002" and "0"
on consecutive invocations is exactly what this produces, and it is why the
2-file fixture looked stable: those runs used explicit file arguments.

### Where this leaves the two asks

Ask 2 from above — *never proceed silently* — still stands and is still the more
important half. Ask 1 is not "make attachment reliable"; attachment is fine. The
fix is that a cached analysis result must either carry the plugin diagnostics it
was computed with, or be invalidated when a plugin is configured.

**This is an upstream bug in the analysis server's result cache, not in this
package.** Nothing in `many_lints` can fix it: the plugin is never asked. It
needs a `dart-lang/sdk` issue against the analysis-driver caching path.

### Workaround until it is fixed

A CI gate must not use a bare `dart analyze`. Either pass explicit file
arguments (`git ls-files '*.dart' | xargs dart analyze`, batched to stay under
the argument limit), or delete `~/.dartServer/.analysis-driver` before the run.
Both make the plugin report reliably; the first is much faster.

### Acceptance test

The suggested "run N times, assert identical counts" test above is right, but it
must invoke `dart analyze` **with a directory argument** and must not touch the
files between runs. With explicit file arguments it passes today and catches
nothing.

Environment for this diagnosis: same as above, plus many_lints at HEAD
(2026-08-26). Verified on a 12-file directory as well as the full project.


## Correction 2026-08-27 — explicit file arguments are NOT a reliable workaround

The 2026-08-26 diagnosis is right about the cache trigger and wrong about the
cure. Two of its claims do not survive measurement:

> Invoked with **explicit file arguments**, the plugin runs every time.

> Scale is irrelevant — a twelve-file directory fails exactly like the 731-file
> `lib/`.

Both are false. There is a **second, independent trigger** that is purely about
scale, and it defeats the recommended workaround on any project big enough to
need it.

### What happens

Passing every Dart file explicitly, on a project of 1279 files:

```
$ git ls-files -z '*.dart' | xargs -0 dart analyze --fatal-infos
No issues found!            # plugin contributed nothing
```

The same files, in batches of 400:

```
$ git ls-files -z '*.dart' | xargs -0 -n 400 dart analyze --fatal-infos
45 issues found.
```

Same files, same config, same invocation form. Only the batch size differs.

### The canary that proves it

Counting findings cannot distinguish "clean" from "plugin never ran", which is
what made the first investigation cost a day. So the control is a file that
**must** produce a diagnostic — a class named `CanaryManager` against a
configured `avoid_banned_names` — appended to the file list:

| Invocation | Canary reported |
|---|---|
| `dart analyze canary.dart` | yes |
| canary + 200 files | yes |
| canary + 700 files | yes |
| canary + 750 files | yes |
| canary + 800 files | yes |
| canary + 850 files | **no** |
| canary + 900 files | **no** |
| canary + 1278 files | **no** |

The cliff sits between **800 and 850 file arguments**. Below it the plugin runs
on every invocation, as the earlier diagnosis says. Above it the plugin
contributes nothing at all, on the first run and every run after, with a cold
cache or a warm one. Deleting `~/.dartServer/.analysis-driver` does not help,
which is what separates this from the cache-hit trigger.

Note the asymmetry that makes this so easy to misread: the run that skips the
plugin reports **fewer** findings, never more. On this project the full-tree run
said "No issues found" while a batched run over the identical file set reported
45. An earlier measurement in the same session recorded 280 from one full-tree
invocation and 0 from the next, so the two triggers can also stack.

### Why it matters more than the first trigger

The first trigger has a documented cure. This one breaks that cure precisely
where it is needed: a project small enough to analyze in one call is small
enough not to care, and any project past ~800 files silently gets nothing. The
workaround section below said "batched to stay under the argument limit" for
`ARG_MAX` reasons; that parenthetical turns out to be load-bearing for
correctness, not just for exec limits.

### Revised workaround

Batch **and** keep each batch well under the cliff:

```sh
git ls-files -z '*.dart' | xargs -0 -n 400 dart analyze --fatal-infos
```

`-n 400` leaves headroom; 800 is the measured edge, not a safe target.

Better, because both triggers are silent and exit 0: keep a canary file in the
repo whose diagnostic is guaranteed, and fail the build when it is **absent**.
That converts either failure mode from a green build into a red one, which is
ask 2 from the original report implemented on the consumer side while the
upstream fix is pending.

### Where this leaves the asks

Ask 2 — *never proceed silently* — is now the whole report. Two unrelated code
paths drop plugin diagnostics, both exit 0, and both are indistinguishable from
a clean run. Whatever the mechanism of either, a configured-but-inactive plugin
must be a build error.

Ask 1 gains a second half: alongside the cache-result fix, find why an
invocation past ~800 file arguments never asks the plugin. Worth checking
whether the analysis server is falling back to a different driver path, or
batching internally, once the file count crosses a threshold.

### Environment

Dart 3.13.1, Flutter 3.47.1, macOS x64 (Intel), many_lints at HEAD (2026-08-27),
local checkout via `path:`. Project: 1279 tracked Dart files (726 under `lib/`).
Each row of the canary table verified in a single session, nothing edited
between runs.

### Acceptance test

Alongside the directory-argument test above: build a fixture of ~1000 files
where exactly one carries a guaranteed diagnostic, pass every file explicitly in
one invocation, and assert the diagnostic is reported. It fails today.
