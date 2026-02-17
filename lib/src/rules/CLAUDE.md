# Lint Rules — Quick Reference

This directory contains lint rule implementations. Each rule extends `AnalysisRule` and uses the `SimpleAstVisitor` pattern.

**Full implementation guides:** [rules-patterns.md](../../../.claude/skills/new-lint/rules-patterns.md) | [rules-recipes.md](../../../.claude/skills/new-lint/rules-recipes.md)
**To create a new lint rule:** use the `/new-lint` skill

## Rule Pattern

Every rule follows: `AnalysisRule` + `_Visitor extends SimpleAstVisitor` + `registerNodeProcessors()` + `rule.reportAtNode()`.

For class suffix naming rules, use the `ClassSuffixValidator` base class (~20 lines vs ~55 lines).

## Key Concepts

- **TypeChecker** (`../type_checker.dart`) — type matching: `fromName()`, `fromUrl()`, `isSuperOf()`, `isAssignableFromType()`
- **Type inference** (`../type_inference.dart`) — `inferContextType()`, `resolveReturnType()`, `isTypeCompatible()`
- **AST helpers** (`../ast_node_analysis.dart`) — `isExpressionExactlyType()`, `maybeGetSingleReturnExpression()`, `firstWhereOrNull`
- **Hook detection** (`../hook_detection.dart`) — `getAllInnerHookExpressions()`, `maybeHookBuilderBody()`
- **String distance** (`../text_distance.dart`) — `computeEditDistance()`
- **Reporting** — `reportAtNode()`, `reportAtToken()`, `reportAtOffset()`, with `{0}` placeholder interpolation
- **Analyzer 10.0.2** — use `node.declaredFragment?.element` (not deprecated `.element`), `node.body` (not `.members`), `namePart.typeName` for class/enum names

## Example Rules

| Pattern | Example | Description |
|---------|---------|-------------|
| Suffix naming | [use_bloc_suffix.dart](use_bloc_suffix.dart) | Uses `ClassSuffixValidator` base class |
| Widget replacement | [prefer_center_over_align.dart](prefer_center_over_align.dart) | Checks constructor params with `isInstanceCreationExpressionOnlyUsingParameter` |
| Type context | [prefer_shorthands_with_enums.dart](prefer_shorthands_with_enums.dart) | Uses `inferContextType()` + `isTypeCompatible()` |
| Pattern matching | [prefer_any_or_every.dart](prefer_any_or_every.dart) | Complex Dart 3 pattern matching on AST |
| Comment analysis | [avoid_commented_out_code.dart](avoid_commented_out_code.dart) | Token stream traversal, `reportAtOffset()` |
| Collection types | [avoid_collection_methods_with_unrelated_types.dart](avoid_collection_methods_with_unrelated_types.dart) | Type relationship checking, `realTarget` |
| Cascade analysis | [avoid_duplicate_cascades.dart](avoid_duplicate_cascades.dart) | Cascade sections, `toSource()` comparison |
| If-case patterns | [prefer_simpler_patterns_null_check.dart](prefer_simpler_patterns_null_check.dart) | Dart 3 if-case pattern analysis |

## Updating Documentation

When discovering new patterns while implementing rules:
1. Add a **brief mention** to this file (table row or bullet point)
2. Add **full details** to the cookbook files in `.claude/skills/new-lint/`
