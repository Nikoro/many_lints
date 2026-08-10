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
| Flatten a callback nest + linked renames | [convert_flat_map_to_do_notation.dart](convert_flat_map_to_do_notation.dart) | Walk **up** to the *outermost* matching call so the assist works from anywhere in the nest, then recurse down collecting one step per level. `builder.addLinkedPosition(SourceRange(...), groupName)` makes each generated name renameable by Tab — compute offsets against the replacement text you are about to write, not against the original source. This is the case for choosing an assist over a fix: when generated names need reviewing, the linked-edit gesture belongs with the conversion, and a fix's "apply all" would bypass it |

## Updating Documentation

When discovering new patterns while implementing assists:
1. Add a **brief mention** to this file (table row or bullet point)
2. Add **full details** to [assists-cookbook.md](../../../.agents/skills/new-lint/assists-cookbook.md)
