# Code Assists — Quick Reference

This directory contains code assist implementations. Assists are standalone refactoring actions, independent of lint diagnostics.

**Full implementation guide:** [assists-cookbook.md](../../../.claude/skills/new-lint/assists-cookbook.md)

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

## Updating Documentation

When discovering new patterns while implementing assists:
1. Add a **brief mention** to this file (table row or bullet point)
2. Add **full details** to [assists-cookbook.md](../../../.claude/skills/new-lint/assists-cookbook.md)
