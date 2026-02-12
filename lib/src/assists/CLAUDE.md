# Code Assist Implementation Cookbook

## 📚 About This Document

This cookbook provides **copy-paste ready patterns** for implementing code assists in the `many_lints` package using **analyzer ^10.0.2**. Assists are standalone code actions that offer helpful refactorings, independent of lint diagnostics.

**Target Audience:** AI agents and developers implementing code assists  
**Analyzer Version:** ^10.0.2  
**Last Updated:** February 2026

---

## 🔄 META-INSTRUCTIONS FOR AGENTS

### When to Update This Cookbook

**You MUST update this cookbook when:**
- ✅ You discover a new assist applicability pattern
- ✅ You find a new node selection or targeting technique
- ✅ You implement a complex AST transformation for assists
- ✅ You discover analyzer ^10.0.2 specific assist behaviors
- ✅ You create helper methods for common assist patterns
- ✅ You find better ways to check assist applicability

### What to Document

When updating, add:
- **Working code example** (tested and verified)
- **File reference** to your implementation (e.g., `[my_assist.dart](my_assist.dart#L10-L20)`)
- **Brief explanation** of when to use this pattern
- **Common pitfalls** if any

### How to Update

1. Find the appropriate section (or create new section if needed)
2. Add your pattern following existing format
3. Include file references with line numbers
4. Update the Pattern Index if adding new sections

---

## 📖 Pattern Index

Quick navigation:

- [Assists vs Fixes](#-assists-vs-fixes)
- [Standard Assist Structure](#-standard-assist-structure)
- [Node Selection & Targeting](#-node-selection--targeting)
- [Applicability Checking](#-applicability-checking)
- [Code Transformations](#-code-transformation-patterns)
- [ChangeBuilder for Assists](#️-changebuilder-for-assists)
- [Helper Utilities](#-helper-utilities)
- [Registration](#-registration)
- [Testing](#-testing)

---

## 🆚 Assists vs Fixes

### Key Differences

| Aspect | Fixes | Assists |
|--------|-------|---------|
| **Purpose** | Resolve lint diagnostics | Offer helpful refactorings |
| **Trigger** | Lint rule violations | Cursor position + AST context |
| **Registration** | `registerFixForRule(RuleCode, Fix)` | `registerAssist(Assist)` |
| **Shows when** | Diagnostic is present | Code pattern matches |
| **Scope** | Tied to specific rule | Global/standalone |

### When to Use Assists

✅ **Use Assists for:**
- Code refactorings (e.g., convert patterns)
- Alternative code styles (e.g., collection-for vs map)
- Convenience transformations
- Non-violation improvements

❌ **Don't Use Assists for:**
- Fixing lint violations → use Quick Fixes instead
- Error corrections → use Quick Fixes
- Required changes → use Lint Rules with Fixes

---

## 🏗️ Standard Assist Structure

### Complete Template

```dart
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

// Optional imports
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:many_lints/src/type_checker.dart';
import 'package:many_lints/src/utils/helpers.dart';

/// Assist that [brief description of what it does].
/// 
/// Example:
/// Before: `iterable.map((e) => e * 2).toList()`
/// After:  `[for (final e in iterable) e * 2]`
class MyAssist extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.myAssist',  // Unique ID (camelCase)
    30,                              // Priority (0-100, lower = higher)
    'Description shown in IDE',     // User-facing label
  );

  MyAssist({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // 1. Find target node at cursor position
    final targetNode = node;
    
    // 2. Navigate to the right AST structure
    MethodInvocation? methodInvocation;
    AstNode? current = targetNode;
    while (current != null) {
      if (current is MethodInvocation) {
        methodInvocation = current;
        break;
      }
      current = current.parent;
    }

    if (methodInvocation == null) return;  // Not applicable

    // 3. Check applicability with pattern matching
    if (!_isApplicable(methodInvocation)) return;

    // 4. Perform transformation
    await _performTransformation(methodInvocation, builder);
  }

  bool _isApplicable(MethodInvocation node) {
    // Detailed checks for when assist should be available
    return true;  // Replace with actual logic
  }

  Future<void> _performTransformation(
    MethodInvocation node,
    ChangeBuilder builder,
  ) async {
    // Apply the code transformation
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(node),
        'transformed code',
      );
    });
  }
}
```

**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart)

---

## 🎯 AssistKind Conventions

### Naming Pattern

**ID:** `'many_lints.assist.<camelCaseDescription>'`

```dart
// ✅ Good examples
'many_lints.assist.convertIterableMapToCollectionFor'
'many_lints.assist.convertToAsync'
'many_lints.assist.extractWidget'
'many_lints.assist.wrapWithBuilder'
```

### Priority Values

**Priority range: 0-100** (lower number = higher priority)

```dart
static const _assistKind = AssistKind(
  'many_lints.assist.myAssist',
  30,  // ← Standard priority for refactorings
  'Convert to collection-for',
);
```

**Guidelines:**
- **0-20**: High priority (common, frequently used refactorings)
- **30**: Standard priority (current example uses this)
- **50+**: Lower priority (less common assists)

### Description

User-facing label in IDE, clear and action-oriented:

```dart
// ✅ Good examples
'Convert to collection-for'
'Extract to method'
'Wrap with Builder'
'Convert to async/await'

// ❌ Avoid
'Helper for converting'  // Not action-oriented
'Use collection-for syntax'  // Vague
```

---

## 🔍 Node Selection & Targeting

### Walking Up the Parent Chain

**Pattern: Find specific parent node type**

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  final targetNode = node;  // Node at cursor
  
  // Walk up until we find the right type
  AstNode? current = targetNode;
  MethodInvocation? methodInvocation;
  
  while (current != null) {
    if (current is MethodInvocation) {
      methodInvocation = current;
      break;
    }
    current = current.parent;
  }

  if (methodInvocation == null) return;  // Assist not applicable
}
```

**When to use:** Cursor could be anywhere within the target construct  
**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart#L30-L40)

---

### Checking Multiple Parent Levels

```dart
// Check if .map() is chained with .toList() or .toSet()
final parent = methodInvocation.parent;
PropertyAccess? propertyAccess;

if (parent is ParenthesizedExpression) {
  // Handle: (iterable.map(...)).toList()
  propertyAccess = parent.parent.tryCast<PropertyAccess>();
} else {
  // Handle: iterable.map(...).toList()
  propertyAccess = parent.tryCast<PropertyAccess>();
}

final toListOrSet = propertyAccess?.propertyName.name;
final isToList = toListOrSet == 'toList';
final isToSet = toListOrSet == 'toSet';

if (!isToList && !isToSet) return;  // Not applicable
```

**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart#L50-L65)

---

## ✅ Applicability Checking

### Pattern Matching for Validation

**Use Dart 3 pattern matching to validate AST structure:**

```dart
bool _isApplicable(MethodInvocation node) {
  // Check method name
  if (node.methodName.name != 'map') return false;
  
  // Pattern match the entire structure
  if (node case MethodInvocation(
    target: Expression(staticType: final targetType?),
    methodName: SimpleIdentifier(name: 'map'),
    argumentList: ArgumentList(
      arguments: [
        FunctionExpression(
          body: final functionBody,
          parameters: FormalParameterList(parameters: [final parameter]),
        ),
      ],
    ),
  )) {
    // Type check
    if (!_iterableChecker.isAssignableFromType(targetType)) {
      return false;
    }
    
    // Additional checks
    return true;
  }
  
  return false;
}
```

**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart#L67-L90)

---

### Type Checking in Assists

```dart
import 'package:many_lints/src/type_checker.dart';

class MyAssist extends ResolvedCorrectionProducer {
  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');
  
  bool _isApplicable(MethodInvocation node) {
    final targetType = node.target?.staticType;
    if (targetType == null) return false;
    
    // Check if target is Iterable
    if (!_iterableChecker.isAssignableFromType(targetType)) {
      return false;
    }
    
    return true;
  }
}
```

**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart#L24)

---

### Helper Method Pattern

**Extract complex validation to helper:**

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  final methodInvocation = _findMethodInvocation();
  if (methodInvocation == null) return;
  
  if (!_isApplicable(methodInvocation)) return;
  
  await _performTransformation(methodInvocation, builder);
}

MethodInvocation? _findMethodInvocation() {
  // Navigation logic
}

bool _isApplicable(MethodInvocation node) {
  // Validation logic
}

Future<void> _performTransformation(
  MethodInvocation node,
  ChangeBuilder builder,
) async {
  // Transformation logic
}
```

**Separates concerns for readability**

---

## 🔄 Code Transformation Patterns

### Extracting Source Code

**Use helper to get return expression:**

```dart
import 'package:many_lints/src/utils/helpers.dart';

final returnExpr = maybeGetSingleReturnExpression(functionBody);
if (returnExpr == null) return;  // Can't convert complex function

final returnSource = returnExpr.toSource();
```

**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart#L92-L95)

---

### Building Replacement Code

```dart
// Determine collection delimiters
final openBracket = isToList ? '[' : '{';
final closeBracket = isToList ? ']' : '}';

// Extract components
final targetSource = target.toSource();
final paramName = parameter.name?.lexeme ?? 'e';
final bodySource = returnExpr.toSource();

// Build final replacement
final replacement = '$openBracket'
    'for (final $paramName in $targetSource) '
    '$bodySource'
    '$closeBracket';
```

**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart#L97-L115)

---

### Multi-Range Replacement

**Replace different parts of the same node:**

```dart
await builder.addDartFileEdit(file, (builder) {
  // Get offsets
  final targetOffset = target.offset;
  final targetEnd = target.end;
  final nodeStart = propertyAccess?.offset ?? methodInvocation.offset;
  final nodeEnd = propertyAccess?.end ?? methodInvocation.end;

  // Replace prefix (before target)
  builder.addSimpleReplacement(
    SourceRange(nodeStart, targetOffset - nodeStart),
    openBracket + 'for (final $paramName in ',
  );

  // Replace suffix (after target)
  builder.addSimpleReplacement(
    SourceRange(targetEnd, nodeEnd - targetEnd),
    ') $bodySource$closeBracket',
  );
});
```

**Two replacements preserve the middle (target) unchanged!**  
**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart#L117-L135)

---

## ✏️ ChangeBuilder for Assists

### Basic Replacement

```dart
await builder.addDartFileEdit(file, (builder) {
  builder.addSimpleReplacement(
    range.node(node),
    'replacement text',
  );
});
```

---

### Using SourceRange

```dart
import 'package:analyzer/source/source_range.dart';

builder.addSimpleReplacement(
  SourceRange(startOffset, length),
  'replacement',
);
```

**More flexible than range factory for precise positioning**

---

### Cascade for Multiple Edits

```dart
await builder.addDartFileEdit(file, (builder) {
  builder
    ..addSimpleReplacement(
      SourceRange(nodeStart, prefixLength),
      'prefix replacement',
    )
    ..addSimpleReplacement(
      SourceRange(suffixStart, suffixLength),
      'suffix replacement',
    );
});
```

**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart#L117-L135)

---

## 🛠️ Helper Utilities

### From helpers.dart

**Import:** `package:many_lints/src/utils/helpers.dart`

#### maybeGetSingleReturnExpression

```dart
Expression? maybeGetSingleReturnExpression(FunctionBody body)

// Returns expression from:
// => expr
// { return expr; }
// Otherwise returns null
```

**Usage in assists:**
```dart
final returnExpr = maybeGetSingleReturnExpression(functionBody);
if (returnExpr == null) return;  // Complex function, can't convert
```

**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart#L92)

---

#### firstWhereOrNull

```dart
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test);
}
```

**Useful for finding optional elements without exceptions**

---

### From type_checker.dart

**Import:** `package:many_lints/src/type_checker.dart`

```dart
// Check types in assists
static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

if (_iterableChecker.isAssignableFromType(type)) {
  // Type is Iterable or subtype
}
```

**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart#L24)

---

## 🔌 Registration

### In lib/many_lints.dart

**Assists are registered globally (not tied to rules):**

```dart
import 'package:many_lints/src/assists/my_assist.dart';

class ManyLintsPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    // Register rules...
    // Register fixes...
    
    // Register assists (standalone)
    registry.registerAssist(MyAssist.new);
  }
}
```

**Note:** 
- Use `.new` tear-off syntax
- No rule association needed
- Assists show on **any** matching code

**Reference:** Registration in lib/many_lints.dart

---

## 🧪 Testing

### Current State

**The project currently has NO tests for assists.**

This is an area for improvement. If implementing tests, they would likely follow patterns similar to:

```dart
// Hypothetical test structure (not yet implemented)
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/assists/my_assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(MyAssistTest));
}

@reflectiveTest
class MyAssistTest extends /* AssistTest base class */ {
  @override
  void setUp() {
    // Setup
    super.setUp();
  }

  void test_converts_pattern() async {
    // Test that assist converts code correctly
  }

  void test_not_applicable_when_complex_function() async {
    // Test that assist doesn't show when not applicable
  }
}
```

**For now: Test manually in a test project**

---

## 💡 Best Practices

### ✅ Do:

1. **Return early** if assist not applicable
   ```dart
   if (node == null) return;
   if (!_isApplicable(node)) return;
   ```

2. **Use pattern matching** for clean AST validation
   ```dart
   if (node case MethodInvocation(
     methodName: SimpleIdentifier(name: 'map'),
     // ...
   )) { }
   ```

3. **Use TypeChecker** for type validation
   ```dart
   if (!_checker.isAssignableFromType(type)) return;
   ```

4. **Extract helper methods** for readability
   ```dart
   _findTargetNode()
   _isApplicable()
   _performTransformation()
   ```

5. **Preserve user code** with `.toSource()`
   ```dart
   final userCode = expression.toSource();
   ```

6. **Handle edge cases**
   ```dart
   // Handle parenthesized expressions
   if (parent is ParenthesizedExpression) {
     parent = parent.parent;
   }
   ```

---

### ❌ Don't:

1. **Don't show assists inappropriately**
   - Return early if context doesn't match

2. **Don't ignore parent wrappers**
   - Check for `ParenthesizedExpression`
   - Walk parent chain if needed

3. **Don't use string matching for types**
   - Use `TypeChecker` instead

4. **Don't forget nullability**
   - Use `staticType?` and null checks

5. **Don't create overly complex assists**
   - Keep transformations focused and predictable

---

## 📋 Common Patterns Summary

### Pattern: Iterable Method Conversion

**Problem:** Convert `.method()` to collection-for  
**Solution:**
1. Walk parent chain to find MethodInvocation
2. Check for chained `.toList()` or `.toSet()`
3. Validate with TypeChecker
4. Extract components with `.toSource()`
5. Build collection-for syntax
6. Replace using SourceRange

**Reference:** [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart)

---

### Pattern: Widget Wrapping

**Problem:** Wrap widget with another widget  
**Approach:**
1. Find widget creation at cursor
2. Extract widget source
3. Build wrapper with original widget as child
4. Replace original with wrapper

---

### Pattern: Extract to Method

**Problem:** Extract expression to method  
**Approach:**
1. Find expression at cursor
2. Determine scope (class/function)
3. Extract expression source
4. Generate method declaration
5. Replace expression with method call
6. Insert method at appropriate location

---

## ✅ Assist Implementation Checklist

1. ✅ Import required packages (analysis_server_plugin, analyzer, analyzer_plugin)
2. ✅ Import helpers if needed (type_checker, helpers)
3. ✅ Extend `ResolvedCorrectionProducer`
4. ✅ Define `static const _assistKind` with:
   - ID: `'many_lints.assist.<camelCase>'`
   - Priority: 0-100 (e.g., 30 for standard)
   - Description: Clear action label
5. ✅ Constructor: `MyAssist({required super.context})`
6. ✅ Override `applicability` → `CorrectionApplicability.singleLocation`
7. ✅ Override `assistKind` → return `_assistKind`
8. ✅ Implement `compute(ChangeBuilder builder)`:
   - Find target node (walk parent chain if needed)
   - Check applicability (type checks, pattern matching)
   - Return early if not applicable
   - Extract source with `.toSource()`
   - Build replacement code
   - Apply with `builder.addDartFileEdit(file, ...)`
9. ✅ Register in lib/many_lints.dart: `registerAssist(MyAssist.new)`
10. ✅ Test manually in a test project
11. ✅ Update this cookbook if you discover new patterns!

---

## 🎓 Learning Path

**For new assist implementers:**

1. ✅ Read this cookbook
2. ✅ Study the example: [convert_iterable_map_to_collection_for.dart](convert_iterable_map_to_collection_for.dart)
3. ✅ Understand the difference between assists and fixes
4. ✅ Practice identifying when code action should be assist vs fix
5. ✅ Use templates from this cookbook
6. ✅ Register in lib/many_lints.dart
7. ✅ Test manually
8. ✅ Update this cookbook with new patterns!

---

## 🔄 Changelog

| Date | Agent/Author | Changes |
|------|-------------|---------|
| Feb 2026 | Initial creation | Extracted patterns from convert_iterable_map_to_collection_for.dart |

**Remember:** When you discover new patterns, update this document following the [Meta-Instructions](#-meta-instructions-for-agents).

---

**Happy assisting! ✨**
