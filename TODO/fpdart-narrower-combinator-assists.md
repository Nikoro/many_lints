# Assists for the narrower fpdart combinators

**Proposed:** 2026-08-26 (from adopting the plugin in a Flutter app and refactoring its fpdart pipelines)
**Status:** OPEN — proposal, nothing implemented
**Affects:** `lib/src/assists/`, and one optional rule

## The gap

`prefer_chain_either` already encodes the idea: when a `flatMap` callback does
something a named combinator does for you, say the name instead. That idea
generalises, and the rest of the family is uncovered:

| Combinator | Rule | Assist |
|---|---|---|
| `chainEither` | `prefer_chain_either` | — |
| `fromNullable` / `fromPredicate` | yes | yes |
| **`andThen`** | no | no |
| **`map`** (as a `flatMap` misuse) | no | no |
| **`chainFirst`** | no | no |
| **`filterOrElse`** | no | no |
| **`sequenceListSeq` / `sequenceList`** | no | no |

Every one of these appeared in a single real codebase while migrating it, and
each was written the long way by a competent author — the long way is simply
what you reach for when `flatMap` is the only chaining tool you have in mind.

## Why assists rather than rules

Three of these are **not** defects, so a diagnostic would be noise:

- `flatMap((_) => next)` works; `andThen` is the same call with a better name.
- `flatMap((v) => TaskEither.right(f(v)))` works; `map` is shorter.
- A hand-rolled `reduce` over a list of tasks works.

Assists fit the "always available, never nagging" shape described in
[assists/AGENTS.md](../lib/src/assists/AGENTS.md), and they are the honest
framing: this is a refactoring the author may want, not a finding.

Two of them (`andThen`, `map`) are mechanical enough that a rule *could* be
argued for later, once the assist has shown how often it fires.

## Proposed assists

### 1. Convert `flatMap` to `andThen`

**Cursor:** on a `flatMap` whose callback parameter is unused (`_`, or a name
never referenced in the body).

**Transform:**

```dart
// before
resetter.reset().flatMap((_) => authRepository.logout())

// after
resetter.reset().andThen(authRepository.logout)
```

`andThen` is literally `flatMap((_) => then())` in `task_either.dart`, so the
transformation is exact. Two output shapes worth handling:

- callback body is a single invocation with no arguments from the closure →
  emit a tear-off (`andThen(repo.logout)`);
- anything else → keep a thunk (`andThen(() => …)`).

**Declines when:** the parameter is referenced anywhere in the body. That is a
real dependency and the assist must not offer.

### 2. Convert `flatMap` to `map`

**Cursor:** on a `flatMap` whose callback body is exactly
`TaskEither.right(expr)` / `Either.right(expr)` / `Option.of(expr)` — i.e. the
callback only re-wraps.

```dart
// before
pipeline.flatMap((v) => TaskEither.right(transform(v)))

// after
pipeline.map(transform)   // or map((v) => transform(v))
```

**Declines when:** the body branches (a conditional returning `left` on one
side is a real `flatMap`).

### 3. Convert a `flatMap` that discards its result to `chainFirst`

**Cursor:** on `flatMap((v) => effect(v).map((_) => v))` — the "run an effect,
keep the original value" shape.

```dart
// before
pipeline.flatMap((user) => audit(user).map((_) => user))

// after
pipeline.chainFirst(audit)
```

This one is worth having precisely because the long form is easy to get subtly
wrong: `chainFirst` in the source also swallows the effect's failure
(`.orElse((l) => TaskEither.right(b))`), which the hand-written version usually
does *not*. So the assist changes behaviour and must say so — either decline,
or offer under a message that names the difference. **Open question**, and the
reason this one is listed third: it may belong as documentation rather than an
assist.

### 4. Convert a manual sequencer to `sequenceListSeq`

**Cursor:** on a `reduce` / `fold` over a `List<TaskEither<...>>` that chains
each element onto the accumulator.

```dart
// before — a private helper in the consuming project
TaskEither<Failure, Unit> _sequence(List<TaskEither<Failure, Unit>> tasks) {
  if (tasks.isEmpty) return TaskEither.right(unit);
  return tasks.reduce((acc, t) => acc.flatMap((_) => t));
}

// after
TaskEither.sequenceListSeq(tasks)
```

Note the empty-list guard the hand-rolled version needs and `sequenceListSeq`
does not — one more reason the library version is preferable.

**Care:** `sequenceList` is concurrent, `sequenceListSeq` is sequential. The
hand-rolled `reduce` is always sequential, so the assist must emit the `Seq`
variant. Offering the concurrent one would be a behaviour change.

### 5. Convert an `if`-guard in a chain to `filterOrElse`

**Cursor:** on a `flatMap` whose body is
`if (!pred(v)) return left(e); return right(v);` (or the ternary form).

```dart
// before
pipeline.flatMap((v) => v.isValid ? TaskEither.right(v) : TaskEither.left(Invalid()))

// after
pipeline.filterOrElse((v) => v.isValid, (v) => Invalid())
```

Lowest priority of the five: the long form is arguably clearer when the
predicate is complex, so this is the most a matter of taste.

## Optional rule

`prefer_and_then` — the `flatMap((_) => …)` case only, since it is the one
where the callback provably ignores its argument and the replacement is exact.
Would belong in the same tier as `prefer_chain_either`. The other four should
stay assists until there is evidence people want them enforced.

## Evidence

From one 730-file app, all found by hand rather than by tooling:

- 5 `flatMap((_) => …)` that are `andThen` — in a logout flow, two catalog
  refreshers (`clear` then `seed`), a notification scheduler, and an account
  deletion. Four of the five predate the migration; they are not one author's
  tic.
- 1 hand-rolled `_sequence` helper, empty-list guard and all.

The `andThen` count is what makes the case: it is the same two-line shape
repeated across unrelated features, which is exactly what an assist is for.

## Implementation notes

- Follow [assists-cookbook.md](../.agents/skills/new-lint/assists-cookbook.md)
  and the `convert_to_lazy_fpdart_type` precedent for the parent-chain walk.
- Reuse the type checkers the existing fpdart rules already use, rather than
  matching on the name `flatMap` alone — an unrelated class with a `flatMap`
  must not be offered these.
- `AssistKind.message` supports `{0}`; name the concrete combinator in the
  lightbulb ("Convert to 'andThen'") rather than a generic phrase.
