# Findings Index

Crucial discoveries and "aha moments" captured during development sessions.
Review before making changes to unfamiliar areas.

| File | Area | Findings | Last Updated |
|------|------|----------|--------------|
| [config-constraints.md](config-constraints.md) | What the analyzer cannot do | 3 | 2026-08-08 |
| [config-mechanism.md](config-mechanism.md) | How config is reached at runtime | 6 | 2026-08-09 |
| [rule-authoring.md](rule-authoring.md) | Writing configurable rules | 8 | 2026-08-09 |
| [testing-tooling.md](testing-tooling.md) | Test harness & CLI quirks | 4 | 2026-08-09 |

## All Finding Titles

### config-constraints.md
- [GOTCHA] [CRITICAL] Analyzer gives plugin rules only severity — no per-rule options exist
- [GOTCHA] [CRITICAL] Unknown keys under `plugins: <name>:` produce user-visible warnings
- [GOTCHA] [CRITICAL] A plugin cannot report diagnostics against YAML files

### config-mechanism.md
- [NOTE] [GOTCHA] Two config sources are supported; the dedicated file wins outright
- [NOTE] [GOTCHA] Per-rule severity override already works with zero code
- [GOTCHA] [CRITICAL] `analyzer: exclude:` is global — there is no native per-rule exclude
- [GOTCHA] [CRITICAL] `RuleContext.currentUnit` is null during `registerNodeProcessors`
- [GOTCHA] [GOTCHA] Rule instances are long-lived singletons shared across analysis contexts
- [GOTCHA] [CRITICAL] Rewriting a diagnostic needs a `DiagnosticReporter` subclass — the listener cannot be wrapped

### rule-authoring.md
- [GOTCHA] [CRITICAL] A `LintCode` built in the constructor goes stale when an option feeds its message
- [GOTCHA] [CRITICAL] `TypeChecker.isSuperOf` is reflexive, so a configured base type matches itself
- [GOTCHA] [CRITICAL] Configuring detection without recognition turns an option into a false positive
- [NOTE] [GOTCHA] A quick fix can read per-rule config, but its `FixKind` cannot depend on it
- [NOTE] [GOTCHA] Nested YAML structure survives config parsing — only accessors are missing
- [NOTE] [NOTE] A shared rule base class makes a whole family configurable in one edit
- [GOTCHA] [CRITICAL] "The rule already does that" argues *for* an option, not against it
- [GOTCHA] [GOTCHA] An option that gates nothing still compiles and still tests green

### testing-tooling.md
- [NOTE] [GOTCHA] Config-dependent rule behavior is testable via the PluginServer harness
- [NOTE] [NOTE] `dart analyze <file>.yaml` does not validate analysis options
- [GOTCHA] [CRITICAL] A regex over `LintCode(` silently captures a third of the rules
- [NOTE] [NOTE] The SDK publishes its lint catalogue as machine-readable JSON
