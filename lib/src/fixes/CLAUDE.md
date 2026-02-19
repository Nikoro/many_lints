# Quick Fixes — Quick Reference

This directory contains quick fix implementations. Each fix extends `ResolvedCorrectionProducer` and is registered for a specific `LintCode`.

**Full implementation guide:** [fixes-cookbook.md](../../../.claude/skills/new-lint/fixes-cookbook.md)
**To create a new lint with fix:** use the `/new-lint` skill

## Fix Pattern

Every fix follows: `ResolvedCorrectionProducer` + `FixKind` + `compute(ChangeBuilder builder)` + `builder.addDartFileEdit(file, ...)`.

- **FixKind ID:** `'many_lints.fix.<camelCase>'`
- **Priority:** All fixes use `DartFixKindPriority.standard`
- **Applicability:** All fixes use `CorrectionApplicability.singleLocation`
- **Constructor:** `MyFix({required super.context})`

## Common Patterns

```dart
// Replace entire node (used in all 15 fixes)
builder.addSimpleReplacement(range.node(targetNode), 'NewText');

// Delete from argument list (handles commas)
builder.addDeletion(range.nodeInList(list, element));

// Replace prefix only
builder.addSimpleReplacement(range.startStart(node, parent.argumentList), 'Prefix.');

// Find named argument
final arg = arguments.whereType<NamedExpression>()
    .firstWhereOrNull((e) => e.name.label.name == 'alignment');
```

## Example Fixes

| Pattern | Example | Description |
|---------|---------|-------------|
| Simple replacement | [prefer_center_over_align_fix.dart](prefer_center_over_align_fix.dart) | Replace widget + delete argument |
| Multiple edits | [avoid_unnecessary_consumer_widgets_fix.dart](avoid_unnecessary_consumer_widgets_fix.dart) | Replace superclass + remove parameter |
| Complex transform | [prefer_switch_expression_fix.dart](prefer_switch_expression_fix.dart) | Switch statement → expression |
| Multi-factory | [add_suffix_fix.dart](add_suffix_fix.dart) | Shared logic for Bloc/Cubit/Notifier suffixes |
| Widget dispatch | [use_gap_fix.dart](use_gap_fix.dart) | Different fix logic per widget type |
| Unwrap try body | [avoid_only_rethrow_fix.dart](avoid_only_rethrow_fix.dart) | Remove try-catch, keep body statements |
| Add catch params | [avoid_throw_in_catch_block_fix.dart](avoid_throw_in_catch_block_fix.dart) | Replace throw + add stack trace param to catch clause |
| Generate overrides | [prefer_overriding_parent_equality_fix.dart](prefer_overriding_parent_equality_fix.dart) | Generate `==`/`hashCode` stubs from instance fields, insert before closing brace |
| Insert in/create method | [always_remove_listener_fix.dart](always_remove_listener_fix.dart) | Insert statement into existing dispose() or create it; find super.dispose() for insertion point |
| Re-derive from type | [dispose_fields_fix.dart](dispose_fields_fix.dart) | Walk up from reported node to VariableDeclaration, re-derive cleanup method from field type instead of parsing diagnostic message |
| Unwrap+add param | [avoid_incorrect_image_opacity_fix.dart](avoid_incorrect_image_opacity_fix.dart) | Unwrap child from wrapper widget + add parameter via string insertion; handle both ConstructorName and SimpleIdentifier report nodes |
| Delete method | [avoid_unnecessary_overrides_in_state_fix.dart](avoid_unnecessary_overrides_in_state_fix.dart) | Line-based deletion of entire MethodDeclaration including annotations using `SourceRange` with line boundary extension |
| Move statement | [proper_super_calls_fix.dart](proper_super_calls_fix.dart) | Delete statement at current position + insert at first/last position; line-boundary whitespace handling via `unitResult.content` |
| Insert destructuring | [prefer_class_destructuring_fix.dart](prefer_class_destructuring_fix.dart) | Re-collect property accesses from block, generate destructuring declaration, insert before first usage with `addSimpleInsertion` + indentation from `unitResult.content` |
| Re-derive from block context | [use_existing_variable_fix.dart](use_existing_variable_fix.dart) | Walk up to enclosing `Block`, scan preceding final/const variable declarations for matching `toSource()`, replace duplicate expression with variable name |
| Multi-edit: pattern + replacement | [use_existing_destructuring_fix.dart](use_existing_destructuring_fix.dart) | Walk up to enclosing `Block`, find `PatternVariableDeclarationStatement` for the source variable, `addSimpleInsertion` to add field to pattern (after last field) + `addSimpleReplacement` to replace property access with variable name |
| Constructor rewrite | [avoid_border_all_fix.dart](avoid_border_all_fix.dart) | Replace constructor call with alternative; handle both `InstanceCreationExpression` and `MethodInvocation` node types; preserve args via `toSource()` |
| Widget replacement | [avoid_expanded_as_spacer_fix.dart](avoid_expanded_as_spacer_fix.dart) | Replace entire widget with simpler alternative; selectively preserve named args (key, flex); handle both node types; preserve const keyword |
| Delete constructor | [avoid_state_constructors_fix.dart](avoid_state_constructors_fix.dart) | Delete entire `ConstructorDeclaration` node via `range.node()` + `addDeletion()` |
| Replace + add import | [prefer_async_callback_fix.dart](prefer_async_callback_fix.dart) | Replace type annotation + `builder.importLibrary(Uri.parse('package:...'))` to auto-add import |
| Callback transform + import | [prefer_compute_over_isolate_run_fix.dart](prefer_compute_over_isolate_run_fix.dart) | Replace method call + transform callback arg (add `_` param) + `importLibrary`; handle closures vs function references differently |
| Constructor rewrite (multi-case) | [prefer_correct_edge_insets_constructor_fix.dart](prefer_correct_edge_insets_constructor_fix.dart) | Switch on constructor name to compute different replacements; shared `_isZero()` helper; mirror rule logic for fix replacement strings; handle both `InstanceCreationExpression` and `MethodInvocation` |
| Multi-pattern fix dispatch | [prefer_for_loop_in_children_fix.dart](prefer_for_loop_in_children_fix.dart) | Dispatch fix by checking `node` type and method name; convert `.map().toList()` → `[for ...]`, `SpreadElement` → `for ...`, `List.generate()` → `[for (var i...)]`, `.fold()` → `[for ...]`; use `maybeGetSingleReturnExpression` for callback bodies; `_extractFoldAddExpression` for fold pattern |
| Add prefix | [use_sliver_prefix_fix.dart](use_sliver_prefix_fix.dart) | Simple prefix addition to class name via `addSimpleReplacement(range.node(targetNode), 'Sliver$currentName')` |
| Static call → extension | [prefer_bloc_extensions_fix.dart](prefer_bloc_extensions_fix.dart) | Replace `Provider.of<T>(ctx)` with `ctx.method<T>()`; extract context arg via `args.first.toSource()`; preserve type args via `typeArguments?.toSource()`; check named args for `listen: true` to choose method |

## Updating Documentation

When discovering new patterns while implementing fixes:
1. Add a **brief mention** to this file (table row or bullet point)
2. Add **full details** to [fixes-cookbook.md](../../../.claude/skills/new-lint/fixes-cookbook.md)
