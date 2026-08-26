# A user-defined rule: match a pattern, offer the project's own fix

**Proposed:** 2026-08-26 (from wanting to enforce a project-local helper no built-in rule can reach)
**Status:** IMPLEMENTED 2026-08-26 as `match_pattern`
**Affects:** a new rule, probably `match_pattern` / `banned_pattern`

## The idea

One configurable rule where the project supplies **both** halves: what to match,
and what to replace it with. Structural search-and-replace, expressed in
`analysis_options.yaml` and delivered as a real quick fix.

```yaml
rules:
  match_pattern:
    patterns:
      - find: 'unawaited\((.+)\)'
        replace: '$1.unawaited()'
        message: 'Prefer the trailing form from many_extensions.'
        in: ['lib/**']

      - find: 'DateTime\.now\(\)'
        replace: 'clock.dateTime.now()'
        message: 'Inject the clock so this stays testable.'
        in: ['lib/**']
        exclude: ['lib/core/clock/**']

      - find: 'Text\((.+), style: Theme\.of\(context\)\.textTheme\.(\w+)\)'
        replace: 'Text($1, style: context.theme.textTheme.$2)'
        message: 'Use the context extension.'
```

## Why this is worth having

Every project accumulates rules that are *specific to it* and that no
general-purpose lint will ever ship:

- "use our `Clock` seam, not `DateTime.now()`"
- "use our trailing `.unawaited()`, not the SDK free function"
- "use `context.theme`, not `Theme.of(context)`"
- "this deprecated helper moved — call the new one"

Today each of those needs either a bespoke rule in this package (which does not
scale, and does not belong here — they encode *someone else's* vocabulary) or a
bash grep in a pre-commit hook, which has no fix, no IDE integration, no
`// ignore:` support, and no AST awareness.

This rule turns a one-off convention into something with the same ergonomics as
a built-in lint: a squiggle where the problem is, a lightbulb that fixes it, and
a suppression comment when the author disagrees.

It also relieves pressure on this package. Several existing `banned_*` rules
exist only because the vocabulary is project-specific; a generic matcher covers
the long tail without a new rule per idea. It is a direct answer to the gap in
[banned-usage-misses-top-level-functions.md](banned-usage-misses-top-level-functions.md):
that request only needs banning *plus a replacement*, which is exactly this.

## The hard part: match on what?

Two designs, with a real trade-off.

### A. Source-text regex

Match against the source range of a node (or the raw line). Simple to
implement, immediately understandable to anyone who knows `sed`, and the
`replace` template is plain capture-group substitution.

Costs: no type information, so `unawaited(...)` matches any function of that
name from any library; formatting differences break patterns (a call split
across lines will not match a single-line pattern); nothing stops a pattern
from producing code that does not parse.

### B. AST pattern

Match a shape — a method invocation with a given name on a given type, an
argument in position N — the way the existing `banned_*` rules do, with the
replacement expressed as a template over the captured nodes.

Costs: a pattern language has to be designed, and the honest options are either
a small DSL or something Dart-shaped that has to be parsed. Much more work,
much better precision.

**Suggestion: start with A, but scope it to AST nodes rather than raw lines.**
Match the *source text of a node kind* the user names, so at least the
boundaries are syntactic:

```yaml
- node: methodInvocation        # or: expression, statement, argument
  find: '^unawaited\((.+)\)$'
  replace: '$1.unawaited()'
```

That keeps the implementation close to `match_class_name_pattern` (which
already regex-matches a name), avoids whole-file text munging, and leaves room
to add a real AST matcher later without changing the config shape.

## Safety requirements

A rule that rewrites code from a config file needs guard rails the other rules
do not:

1. **The fix must be opt-in per pattern.** A `find`/`message` pair with no
   `replace` reports only. Nothing rewrites unless the author asked.
2. **Parse the result before offering it.** If applying the template produces
   source that does not parse, drop the fix and keep the diagnostic. This is
   cheap and prevents the worst outcome.
3. **Never auto-apply across a project.** A `dart fix --apply` over a
   hand-written regex is a footgun; treat these fixes as
   `CorrectionApplicability.singleLocation` unless proven otherwise.
4. **An invalid pattern is ignored, not thrown** — same as
   `match_class_name_pattern` and every other malformed option.
5. **Templates get one capture syntax**, documented, with a test per case
   (`$1`, `$0` for the whole match, escaping for a literal `$`).

## Existing pieces this can reuse

- `RuleConfig.patternOption` already compiles a configured `RegExp` and
  swallows an invalid one.
- `BannedEntry` already models `deny` / `denyPatterns` / `paths` / `message`
  and the `in:`-glob scoping around them; a `PatternEntry` can mirror that
  shape so the config stays familiar.
- 96 fixes already build edits with `addSimpleReplacement`; the fix here is the
  same call with a template-substituted string.
- `match_class_name_pattern` is the precedent for "reports nothing until
  configured" and for documenting a regex option.

## Open questions

- **Naming.** `match_pattern` reads like the class-name rule; `banned_pattern`
  is closer to the `avoid_banned_*` family but wrong for the "rewrite" case,
  since not every pattern is a ban.
- **Should the fix be a fix or an assist?** A fix attaches to the diagnostic,
  which is right when the pattern is a genuine ban. For a "we prefer X" pattern
  an assist is the softer tool — possibly both, selected by a per-entry key.
- **Multi-file / import handling.** A replacement that names a symbol not in
  scope produces broken code that parses fine. Either require the author to
  handle it, or add an optional `import:` per entry that the fix ensures.

## Why it is not obviously a good idea

Worth stating the case against, since this rule is unusually powerful:

- It moves logic from a reviewed Dart file into an unreviewed YAML blob.
- A regex over source text is exactly the tool this package exists to replace;
  shipping one risks legitimising the thing everywhere else in the package
  argues against.
- The failure mode is bad: a wrong pattern rewrites working code, and the
  author is likelier to trust a lightbulb than a grep.

The counter is that projects are *already* doing this with bash hooks, with
none of the guard rails above. Bringing it inside gives it AST boundaries,
parse validation, `// ignore:` support and IDE feedback.

## Implemented 2026-08-26 — `match_pattern`

Shipped as design **A**, scoped to AST nodes, with the fix included.

- `lib/src/pattern_entry.dart` — `PatternEntry`, `PatternNode`, template
  expansion, mirroring `BannedEntry`'s `in:`/`message:` shape.
- `lib/src/rules/match_pattern.dart` — the rule.
- `lib/src/fixes/match_pattern_fix.dart` — the quick fix.
- No preset. Silent until `patterns:` is configured.

### Decisions taken

**Name: `match_pattern`.** `banned_pattern` was rejected for the reason the
proposal anticipated: not every pattern is a ban, and half the motivating cases
are "we prefer X" with a rewrite.

**Node kinds: `methodInvocation` (default) and `propertyAccess`.** Two, not
one, and not the full set. `methodInvocation` alone cannot express the
`Theme.of(context).textTheme` → `context.theme.textTheme` case: the matched
node stops at the call and the trailing `.textTheme` sits outside it. The wider
kinds (`expression`, `statement`, `argument`) were left out because a pattern
tested at every nesting level is far easier to point somewhere unintended.
`node:` is in the config from day one, so adding kinds later is additive.

**Capture syntax: `$0`..`$9`, `$$` for a literal.** One escape, and it reads
the way it does in a shell. A group that did not participate expands empty; a
`$` followed by anything else is left alone rather than swallowed.

**Fix, not assist.** The open question resolved toward a fix because it
attaches to the diagnostic, which is what makes the lightbulb appear where the
squiggle is. An assist for the softer "we prefer X" case is still available
later, as a per-entry key.

### Guard rails, all four implemented and tested

1. **Opt-in per pattern.** No `replace:` means report-only.
2. **Parsed before offering.** The expanded template is parsed; if it does not
   parse the fix is dropped and the diagnostic stands, so a wrong pattern
   cannot turn working code into a syntax error.
3. **Never bulk-applied.** `CorrectionApplicability.singleLocation`.
4. **Invalid config is ignored, not thrown.** A bad regex, or a `node:` naming
   no known kind, drops that entry. A `node:` typo deliberately drops the entry
   rather than defaulting to calls, which would silently retarget the pattern.

Guard rails 1 and 2 needed a way to assert that **no** fix is offered, which
the fix harness had no API for. `FixHarness.expectNoFix` is new and additive:
it still requires the diagnostic, so it cannot pass by the rule having gone
silent.

### The unimplemented open question

**Imports.** A replacement naming a symbol that is not in scope produces code
that parses but does not compile. Left to the author and documented as such;
the optional `import:` key is still a reasonable future addition.

### Verified against the reporting project

Configured in that Flutter app for the case that prompted the whole thread:

```yaml
match_pattern:
  patterns:
    - find: '^unawaited\((.+)\)$'
      replace: '$1.unawaited()'
      message: 'Prefer the trailing .unawaited() from many_extensions.'
      in: ['lib/**']
```

**87 findings across the repo**, each carrying a working fix. The config was
not left enabled there — taking on 87 rewrites is that project's call, not this
one's.

This closes the "banning plus a replacement" half of
[banned-usage-misses-top-level-functions.md](banned-usage-misses-top-level-functions.md).
