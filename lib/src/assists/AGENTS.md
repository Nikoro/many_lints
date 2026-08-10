# Code Assists — Quick Reference

This directory contains code assist implementations. Assists are standalone refactoring actions, independent of lint diagnostics.

**Full implementation guide:** [assists-cookbook.md](../../../.agents/skills/new-lint/assists-cookbook.md)

**Testing:** two routes, pick by what you are asserting.

- **`CorrectionProducerContext` directly** — `PubPackageResolutionTest` +
  `CorrectionProducerContext.createResolved(...)`, run `compute()`, apply the
  edits. Fast, no plugin server. Reference:
  [convert_iterable_map_to_collection_for_test.dart](../../../test/convert_iterable_map_to_collection_for_test.dart).
- **`FixHarness.applyAssist(source, assistId)`** (`test/fix_harness.dart`) —
  drives a real `PluginServer` through `edit.getAssists`, marking the cursor
  with `^` in the fixture. Slower, but it is the only route that exercises
  registration and returns `linkedEditGroups`, so it is the one to use when the
  assist offers linked renames or when you want the same end-to-end guarantee
  the fix output tests give. Batches live under `test/assist_output/`.

`analyzer_testing` has no assist base class either way — do not conclude from
that that assists are untestable.

## Assists vs Fixes

| Aspect | Fixes | Assists |
|--------|-------|---------|
| **Purpose** | Resolve lint diagnostics | Offer helpful refactorings |
| **Trigger** | Lint violations | Cursor position + AST context |
| **Registration** | `registerFixForRule(RuleCode, Fix)` | `registerAssist(Assist)` |

## Assist Pattern

Every assist follows: `ResolvedCorrectionProducer` + `AssistKind` (priority 0-100) + `compute(ChangeBuilder builder)`.

Key differences from fixes:
- Walk **parent chain** to find target node (cursor could be anywhere)
- Check **applicability** before transforming (return early if not applicable)
- Register with `registry.registerAssist(MyAssist.new)` (no rule association)

## Common Patterns

```dart
// Walk parent chain to find target
AstNode? current = node;
while (current != null) {
  if (current is MethodInvocation) break;
  current = current.parent;
}

// Multi-range replacement (preserve middle)
builder.addSimpleReplacement(SourceRange(start, prefixLen), 'prefix');
builder.addSimpleReplacement(SourceRange(suffixStart, suffixLen), 'suffix');
```

## Example Assists

| Pattern | Example | Description |
|---------|---------|-------------|
| Iterable conversion | [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart) | `.map().toList()` → collection-for |
| Rewrite a signature + transplant a body | [convert_to_lazy_fpdart_type.dart](convert_to_lazy_fpdart_type.dart) | `Future<Either>`/`Either` → `TaskEither`, `Future<Option>`/`Option` → `TaskOption`. `AssistKind.message` supports `{0}`, filled from the producer's `assistArguments` — use it so the lightbulb names the concrete target instead of a generic phrase. Two traps worth remembering: (1) **`toSource()` discards line breaks**, so transplanting a multi-statement block with it silently collapses the body onto one line — copy `unitResult.content.substring(node.offset, node.end)` and re-indent instead; (2) read type arguments from the **written** `NamedType`, not the resolved `DartType`, or aliases and import prefixes expand into names that may not be in scope where the replacement lands. Probe the real output with a throwaway test before writing expectations — the first version of this assist emitted a doubled `)` that no amount of reasoning caught |
| Expand a constructor into a statement | [convert_try_catch_constructor_to_try_statement.dart](convert_try_catch_constructor_to_try_statement.dart) | `Either`/`TaskEither`/`Option.tryCatch` → an explicit `try`/`catch`. Two things generalise: (1) a *statement* replacement is only legal where a statement can live, so match the whole `FunctionBody` (both `=> e` and `{ return e; }`) and decline mid-expression; (2) generated code must not arrive carrying a **new** diagnostic — an `onError` may declare an unused stack trace, a `catch` clause may not, so the parameter is dropped when the body never reads it. Verify emitted source against the real package, not just the stub — the stub proves only your own assumptions |
| Unfold a block back into a callback nest | [convert_do_notation_to_flat_map.dart](convert_do_notation_to_flat_map.dart) | The inverse of the assist below, and the case for **deliberately declining**: `Do` is imperative and `flatMap` is a fixed chain of continuations, so only the straight-line shape (`final x = $(...)` bindings + one `return`) can be unfolded — a branch would have to be CPS-transformed. Recognise exactly the shape the forward assist emits and return early on everything else. Pairs with `FixHarness.assistIds()`, which lists what is offered at a cursor so "must not be offered here" is a real assertion rather than a caught `fail()` |
| Flatten a callback nest + linked renames | [convert_flat_map_to_do_notation.dart](convert_flat_map_to_do_notation.dart) | Walk **up** to the *outermost* matching call so the assist works from anywhere in the nest, then recurse down collecting one step per level. `builder.addLinkedPosition(SourceRange(...), groupName)` makes each generated name renameable by Tab — compute offsets against the replacement text you are about to write, not against the original source. This is the case for choosing an assist over a fix: when generated names need reviewing, the linked-edit gesture belongs with the conversion, and a fix's "apply all" would bypass it |

## Updating Documentation

When discovering new patterns while implementing assists:
1. Add a **brief mention** to this file (table row or bullet point)
2. Add **full details** to [assists-cookbook.md](../../../.agents/skills/new-lint/assists-cookbook.md)
