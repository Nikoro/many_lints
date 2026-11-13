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

Pre-commit checks staged content with `staged --no-review`, runs the lightweight
hook tests, checks the whole tree, then validates independent review last. The
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
Static type checking and duplicate scanning are deferred; adding them requires
an owner decision rather than a new mandatory runtime dependency.
