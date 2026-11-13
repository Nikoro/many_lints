# Quality gates

LINT_SYNC_REPORT.md is the persistent rule-audit artifact owned by the
sync-official-lints skill. Its checked and unchecked actionable entries are
preserved across audits, so this exact report is a journals home alongside TODO,
decisions and the changelog. Other progress reports remain subject to the gate.

Run `tool/setup.sh` to install or fast-forward the ignored shared tool clone and
configure `.githooks`. Git access and Python >=3.11 are required. Missing, invalid
or dirty installations fail with an actionable error; hooks never skip a gate
because the private repository cannot be reached. Fix shared faults in commit_gate's
own repository, then update the clean installed clone.

## Commit hooks

Pre-commit checks staged content with `staged --no-review`, scans duplicate
code with staged-input validation, runs the lightweight hook tests, checks the whole tree, then validates independent review last. The
existing Dart, examples and documentation checks stay in CI and the contributor
workflow; their order and scope are unchanged by the shared gate installation.

Finalize staging and run `tool/commit_gate.sh review` before committing. Start the
fresh reviewer described by its brief, then inspect `tool/commit_gate.sh trailers`.
Commit-msg validates the exact reviewed tree, fix-test changes, retained-note
acknowledgments and any improvement/owner-decision trailers.

## Policy and test ownership

All five shared gates are enabled. Public API docs are permitted in
`lib/many_lints.dart`. `example/lib/**` is deliberately comment-bearing fixture
material: LINT markers, bad/good examples and suppression text are consumed by
example verification and documentation generation. This exception does not allow
comments in implementation code, build scripts or ordinary documentation sources.

Rule tests use the existing `test/<rule>_test.dart` layout, including reflective
`test_*` methods. `commit_gate.toml` maps helpers to their owning behavioral suites,
fixes to the actual fix-output batch exercising their registration, and assists
to the real PluginServer assist-output tests. These are existing behavior tests,
not a claim that the default simulated layout uncovered hundreds of untested rules.
A fix changes the mapped behavioral test; update a mapping when ownership moves.

`TODO/` is the established home for pending work and reproduction evidence. Finished
investigations are deleted after their durable conclusions move into the development
guides. Other docs remain subject to the journals gate. Rule pages and detailed
development guides are review context on demand; linked instruction references
remain mandatory.

## Required contributor checks

Run formatting with the primary-constructors experiment, `dart analyze --fatal-infos`,
`dart run tool/verify_documentation.dart`, `dart run tool/verify_examples.dart`, the
complete `dart test` suite, and `bun run build` from `docs/`. The rule examples and
assist fixtures assert actual plugin behavior. See `CONTRIBUTING.md` for commands.

## Developer analysis tools

Optional ShellCheck and Ruff checks are approved for repository tooling and run
when installed. They remain developer tools, never application dependencies.
Python type checking is implemented in the shared Commit Gate repository. The
application keeps its existing Dart or Swift type analysis.

## Duplicate code

The owner explicitly requested duplicate detection in the Commit Gate rollout,
superseding the earlier deferral. jscpd is a repository developer tool, with no
application or shared-gate runtime dependency. Install it before the hook
installer, which validates the scan before activating hooks and preserves the
previous hook configuration when tooling is unavailable or the scan fails:

```sh
npm --prefix scripts/quality/js ci --ignore-scripts --no-audit --no-fund
tool/python.sh scripts/quality/check_duplicates.py
```

The ordinary commit hook invokes the checker through the existing Python
launcher with `--staged`. That mode requires
all scanned source and detector policy inputs to match the index, so an unstaged
fix or baseline edit cannot conceal a staged copy. Missing tools or unreadable
policy fail with an installation/error message; hooks never install packages or
access the network.

The scan covers `lib`, using `minLines: 10`
and `minTokens: 100`; generated Dart output is excluded explicitly. `.gitignore`
does not control source selection. Existing repeated implementations remain
visible in `.jscpd-baseline.json`, which stores both fingerprints and their
counts. The initial source snapshot contains 11 clone pairs. New clone
fingerprints or additional copies of an existing clone fail the hook. The
threshold is zero new clones, rather than a permitted duplication percentage.

Index entries marked `assume-unchanged` or `skip-worktree` are rejected before
comparing source files, including when a caller selects an alternate index.
Ignored untracked handwritten sources must also be staged; explicitly excluded
generated files do not need to be staged for this scan.

A baseline is not regenerated by a hook. To deliberately change accepted debt,
inspect the matching source blocks, run the following command, stage the
baseline with the source change, and include it in independent review:

```sh
scripts/quality/js/node_modules/.bin/jscpd --config .jscpd.json --update-baseline
```

Do not use `--changed`: its automatically refreshed HEAD baseline would accept
new duplication after each commit. Remove accepted fingerprints when their
source copies are eliminated; do not raise the token/line limits to pass a change.

CI provisions Node 24 and the locked detector dependencies, runs the isolated
Python tooling regressions, then invokes the quality check. Package installation
stays outside commit hooks.
