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
| Property+method chain | [avoid_map_keys_contains.dart](avoid_map_keys_contains.dart) | PrefixedIdentifier vs PropertyAccess duality |
| Test matcher validation | [avoid_misused_test_matchers.dart](avoid_misused_test_matchers.dart) | Method name matching, nullability/type category checks |
| Try-catch analysis | [avoid_only_rethrow.dart](avoid_only_rethrow.dart) | CatchClause body inspection, RethrowExpression detection |
| Throw in catch | [avoid_throw_in_catch_block.dart](avoid_throw_in_catch_block.dart) | RecursiveAstVisitor for ThrowExpression, function boundary stopping |
| Return in try-catch | [prefer_return_await.dart](prefer_return_await.dart) | ReturnStatement visitor, async detection, Future type check |
| Matcher type check | [prefer_test_matchers.dart](prefer_test_matchers.dart) | Check if arg extends a class by walking `allSupertypes` |
| Unassigned return value | [avoid_unassigned_stream_subscriptions.dart](avoid_unassigned_stream_subscriptions.dart) | `node.staticType` + `parent is ExpressionStatement` for discarded values |
| Negative literal detection | [prefer_contains.dart](prefer_contains.dart) | `-1` is `PrefixExpression(MINUS, IntegerLiteral(1))`, BinaryExpression with reversed operands |
| Ancestor member override | [prefer_overriding_parent_equality.dart](prefer_overriding_parent_equality.dart) | Walk `allSupertypes` via `InterfaceType.methods`/`getters`, AST-level current class check |
| ObjectPattern analysis | [prefer_wildcard_pattern.dart](prefer_wildcard_pattern.dart) | `ObjectPattern.type.name.lexeme` + `fields.isEmpty` check, recursive pattern walking |

## Updating Documentation

When discovering new patterns while implementing rules:
1. Add a **brief mention** to this file (table row or bullet point)
2. Add **full details** to the cookbook files in `.claude/skills/new-lint/`
