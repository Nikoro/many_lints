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

## Updating Documentation

When discovering new patterns while implementing fixes:
1. Add a **brief mention** to this file (table row or bullet point)
2. Add **full details** to [fixes-cookbook.md](../../../.claude/skills/new-lint/fixes-cookbook.md)
