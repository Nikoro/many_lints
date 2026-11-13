# Regression boundaries

## Analyzer identity and asynchronous state

The stale-read visitor stops at callback boundaries. A field mentioned inside a
callback being installed is not a dependency of the value assigned before the
callback runs. Tests distinguish that shape from reads and writes after one await.

Mounted guards are structural: `if (!mounted || failed) return` excludes the
unmounted path; negative conjunctions do not. `if (mounted && ready)` is a valid
positive wrapper; positive disjunctions are not. An await inside a guarded branch
opens a fresh gap. Keep the else branch covered separately.

## Type matching and faithful stubs

The immutable-state rule's name-based strategy excludes state-like mutable bases
through `isStateElement`. Its Bloc-specific sibling stays type-based. A superclass
with semantic `@immutable` metadata already establishes immutable ancestry; an
annotation on the class itself does not suppress subtype propagation. A fake meta
library must be named `meta` and export `immutable` or `Immutable` for semantic
metadata checks to see it.

Flutter stubs must follow actual constructor signatures. `Card` has no padding
parameter; `ListView` inherits one from `BoxScrollView`. `Border` takes four sides,
and `BorderRadius.circular` is a non-const generative constructor. `SliverList.list`
really does accept children. Confirm API existence before deleting a rule case.

## Qualified bans and configurable rewrites

`banned_usage` handles bare top-level names as well as qualified members. A bare
`unawaited` also matches a same-named extension, so use `dart:async#unawaited` when
only the SDK declaration is forbidden. Extension members use `Extension.member`,
not the extended type's name.

`match_pattern` is silent until configured. It matches method invocations or
property access, expands `$0` through `$9` and `$$`, and offers a single-location
fix only when the expansion parses. Invalid patterns or node kinds are dropped.
Replacement imports remain the author's responsibility; parsing does not prove
that every referenced name is in scope.

## fpdart conversions

The flatMap-narrowing assists share `fpdart_chain_call.dart`; the parameter's
resolved element decides whether it is unused. `chainFirst` swallows the effect's
failure through `orElse`, so its label states the change and its priority is below
exact conversions. The inverse assist is offered only for exact, motivated cases.

The trimmed mock SDK lacks `Iterable.reduce`. A typed collection assist needs a
faithful extension in its fixture or it may decline because the call is unresolved,
which looks like a registration failure. Keep positive and declined output cases.

## Configuration tests

`ManyLintsRuleTest` supplies `testPackageRootPath` and writes `many_lints.yaml`.
Rule tests can overwrite that file before analysis to exercise per-rule options.
Use a real PluginServer package root for end-to-end configuration loading and
discovery tests. Pair negative
assertions with asymmetric positive controls: silence alone cannot prove the rule
ran. State lifecycle lists answer different questions: super-call order, implicit
rebuilds and disposal are not one interchangeable set.
