# Code Assist Implementation Cookbook

## About This Document

This cookbook provides **copy-paste ready patterns** for implementing code assists in the `many_lints` package using **analyzer ^14.1.0**. Assists are standalone code actions that offer helpful refactorings, independent of lint diagnostics.

**Target Audience:** AI agents and developers implementing code assists
**Analyzer Version:** ^14.1.0
**Last Updated:** August 2026

---

## META-INSTRUCTIONS FOR AGENTS

### When to Update This Cookbook

**You MUST update this cookbook when:**
- You discover a new assist applicability pattern
- You find a new node selection or targeting technique
- You implement a complex AST transformation for assists
- You discover analyzer ^14.1.0 specific assist behaviors
- You create helper methods for common assist patterns
- You find better ways to check assist applicability

### What to Document

When updating, add:
- **Working code example** (tested and verified)
- **File reference** to the real implementation (for example,
  `lib/src/assists/my_assist.dart`; link it only after the file exists)
- **Brief explanation** of when to use this pattern
- **Common pitfalls** if any

### How to Update

1. Find the appropriate section (or create new section if needed)
2. Add your pattern following existing format
3. Include file references with line numbers
4. Update the Pattern Index if adding new sections
5. Also update the lean quick reference at `lib/src/assists/AGENTS.md` with a brief mention of the new pattern

---

## Pattern Index

Quick navigation:

- [Assists vs Fixes](#assists-vs-fixes)
- [Standard Assist Structure](#standard-assist-structure)
- [Node Selection & Targeting](#node-selection--targeting)
- [Applicability Checking](#applicability-checking)
- [Code Transformations](#code-transformation-patterns)
- [ChangeBuilder for Assists](#changebuilder-for-assists)
- [Helper Utilities](#helper-utilities)
- [Bidirectional Assist Pairs](#bidirectional-assist-pairs)
- [Emitting a Tear-Off vs a Closure](#emitting-a-tear-off-vs-a-closure)
- [Registration](#registration)
- [Testing](#testing)

---

## Assists vs Fixes

### Key Differences

| Aspect | Fixes | Assists |
|--------|-------|---------|
| **Purpose** | Resolve lint diagnostics | Offer helpful refactorings |
| **Trigger** | Lint rule violations | Cursor position + AST context |
| **Registration** | `registerFixForRule(RuleCode, Fix)` | `registerAssist(Assist)` |
| **Shows when** | Diagnostic is present | Code pattern matches |
| **Scope** | Tied to specific rule | Global/standalone |

### When to Use Assists

**Use Assists for:**
- Code refactorings (e.g., convert patterns)
- Alternative code styles (e.g., collection-for vs map)
- Convenience transformations
- Non-violation improvements

**Don't Use Assists for:**
- Fixing lint violations -> use Quick Fixes instead
- Error corrections -> use Quick Fixes
- Required changes -> use Lint Rules with Fixes

---

## Standard Assist Structure

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
import 'package:many_lints/src/ast_node_analysis.dart';

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

**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

---

## AssistKind Conventions

### Naming Pattern

**ID:** `'many_lints.assist.<camelCaseDescription>'`

```dart
// Good examples
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
  30,  // <- Standard priority for refactorings
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
// Good examples
'Convert to collection-for'
'Extract to method'
'Wrap with Builder'
'Convert to async/await'

// Avoid
'Helper for converting'  // Not action-oriented
'Use collection-for syntax'  // Vague
```

---

## Node Selection & Targeting

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
**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

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

**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

---

## Applicability Checking

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

**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

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

**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

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

## Code Transformation Patterns

### Extracting Source Code

**Use helper to get return expression:**

```dart
import 'package:many_lints/src/ast_node_analysis.dart';

final returnExpr = maybeGetSingleReturnExpression(functionBody);
if (returnExpr == null) return;  // Can't convert complex function

final returnSource = returnExpr.toSource();
```

**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

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

**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

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
**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

---

## ChangeBuilder for Assists

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

**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

---

## Helper Utilities

### From ast_node_analysis.dart

**Import:** `package:many_lints/src/ast_node_analysis.dart`

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

**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

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

**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

---

## Bidirectional Assist Pairs

An assist that narrows a shape (`flatMap` → `andThen`) invites the inverse. `Do` notation ↔ `flatMap` was the first pair here; the fpdart combinator family added a second. The inverse is worth writing **only when both conditions hold**:

1. **The transformation is exact in both directions.** If the narrow form is defined as the wide one, expanding it cannot change meaning.
2. **There is a real reason to go back.** Usually: *the narrow form hides a value the next edit needs.* You write `andThen(logout)`, then the next step turns out to depend on the previous result — the first edit is always expanding back to a `flatMap` whose callback names it.

Both conditions failed for two of the five fpdart combinators, and saying why is more useful than the pattern itself:

- **`chainFirst`** — expanding it honestly requires emitting its `.orElse((l) => right(b))` too, which nobody wants to read; the shorter form people expect **silently changes error handling**. Either output is worse than no assist.
- **`sequenceListSeq`** — the expansion is a hand-rolled fold needing an empty-list guard the library version does not. A downgrade in every case.

**Prefer one assist over N when the inverse covers several shapes.** `ExpandToFlatMap` handles `andThen`, `map` *and* `filterOrElse` behind one `AssistKind`: one lightbulb entry at the cursor, one code path, one set of tests. Three separate assists would put three entries on the same cursor for what a reader thinks of as one action.

```dart
enum _Combinator {
  andThen(name: 'andThen', arity: 1),
  map(name: 'map', arity: 1),
  filterOrElse(name: 'filterOrElse', arity: 2);
  // ...
  static _Combinator? byName(String name) { /* ... */ }
}

// One compute(), dispatching on which combinator the cursor sits on.
final replacement = switch (combinator) {
  _Combinator.andThen => _expandAndThen(arguments),
  _Combinator.map => _expandMap(arguments, wrapper),
  _Combinator.filterOrElse => _expandFilterOrElse(arguments, wrapper),
};
```

**Always add a round-trip test.** Narrow, then expand, and assert you are back where you started. It is the cheapest way to catch the two directions drifting apart.

**Reference:** [expand_to_flat_map.dart](../../../lib/src/assists/expand_to_flat_map.dart), and the `round-trips` tests in [assists_test.dart](../../../test/assist_output/assists_test.dart).

### When a transformation is *not* exact, say so in the label

`AssistKind.message` is the only place a reader learns that a refactoring changes behaviour — nobody opens the source before clicking a lightbulb. When an assist is worth offering but is not semantics-preserving, put the difference **in the message** and drop its priority below the exact conversions:

```dart
static const _assistKind = AssistKind(
  'many_lints.assist.convertFlatMapToChainFirst',
  // Below the exact conversions: this one asks the author to accept a
  // change in behaviour, so it should not sit above assists that do not.
  29,
  "Convert to 'chainFirst' (ignores the effect's failure)",
);
```

The alternative — a neutral label plus a doc-comment warning — hides the cost exactly where the decision is made.

---

## Emitting a Tear-Off vs a Closure

An assist that moves a callback between shapes has to decide whether to emit `andThen(repo.logout)` or `andThen(() => repo.logout())`. The rule that held up across five assists:

**Emit a tear-off only for a bare invocation that needs nothing from the closure** — no arguments, no type arguments:

```dart
String andThenArgumentFor(Expression body) {
  if (body is MethodInvocation &&
      body.argumentList.arguments.isEmpty &&
      body.typeArguments == null) {
    final target = body.realTarget;
    final receiver = target == null ? '' : '${target.toSource()}.';
    return '$receiver${body.methodName.name}';
  }

  return '() => ${body.toSource()}';
}
```

Anything else keeps a closure, because tearing it off is either impossible (arguments) or changes *when* it is evaluated (a constructor call, a property read).

**Going the other way, inline the closure body when the names already match.** Expanding `map((raw) => transform(raw))` should produce `flatMap((raw) => Wrapper.of(transform(raw)))`, not an immediately-invoked lambda. Inline **only** when the closure's own parameter names are the ones the expansion binds — otherwise the body references a name that no longer exists:

```dart
if (body is ExpressionFunctionBody &&
    parameters != null &&
    parameters.length == arguments.length &&
    _namesMatch(parameters, arguments)) {
  return body.expression.toSource();
}
return '${callback.toSource()}(${arguments.join(', ')})';
```

A tear-off brought no parameter name of its own, so synthesise one (`value`) and suffix it if something in an enclosing closure already uses it, rather than shadowing.

**Read the wrapper from what the call *returns*, not from the receiver.** A `map` changes the value type, so `p.map(f)` on a `TaskEither<L, A>` returns `TaskEither<L, B>` — building from the receiver would still be right here, but only by luck. `invocation.staticType` is the honest source. Every fpdart type declares `.of`, so one code path covers `Option`, `Either`, `Task`, `IO` and their variants; only the failable three have `.left`.

---

## Registration

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

## Testing

### Testing Assists

`analyzer_testing` has no dedicated assist test base class, so there are two routes. Pick by what you need to assert.

**1. `CorrectionProducerContext` directly** — `PubPackageResolutionTest` plus `CorrectionProducerContext.createResolved()`: manually resolve the code, create a context at a target offset, run the assist's `compute()`, and verify the produced edits. Fast, and enough for most assists.

**2. `FixHarness.applyAssist(source, assistId)`** (`test/fix_harness.dart`) — drives a real `PluginServer` through `edit.getAssists`, with the cursor marked `^` in the fixture. Slower, but it is the only route that:

- exercises **registration** (route 1 constructs the assist directly, so a missing `registerAssist` still passes), and
- returns **`linkedEditGroups`**, letting a test assert which names the assist made renameable.

Reach for route 2 when the assist offers linked renames, or when you want the same end-to-end guarantee the fix output tests give. Batches live under `test/assist_output/`; see [assists_test.dart](../../../test/assist_output/assists_test.dart).

**Asserting an assist is NOT offered.** `applyAssist` fails the test when the assist it names is missing, which is right for positive cases but makes "this must not be offered here" awkward. Use `FixHarness.assistIds(content)`, which returns every id offered at the `^` cursor:

```dart
final offered = await harness.assistIds(r'''
...p.chainFir^st(audit);
''', multiFilePackages: {'fpdart': fpdartStubFiles});

expect(offered, isNot(contains('many_lints.assist.expandToFlatMap')));
```

An assist declining a shape it cannot safely transform is part of its contract, so it deserves a first-class assertion rather than a caught failure.

### GOTCHA: the mock SDK's `Iterable` has no `reduce`

**Symptom:** a type-based assist over a collection is never offered, and the harness reports `Got: []` — no assists at all at that offset, which reads like a registration failure.

**Cause:** `createMockSdk` ships a deliberately minimal `Iterable`. It declares `fold`, `where`, `map`, `firstWhere` and friends, but **not `reduce`**. A fixture calling `values.reduce(...)` therefore does not resolve, so any assist resolving types declines — correctly, but for a reason that has nothing to do with the code under test.

**Fix:** supply the missing member in the fixture itself.

```dart
// The test SDK's minimal `Iterable` declares no `reduce`, so the fixture
// supplies one. The assist resolves types rather than names, so an
// unresolved call would make it decline for the wrong reason.
extension <E> on Iterable<E> {
  E reduce(E Function(E value, E element) combine) => throw '';
}
```

A **name**-matching rule can instead assert the resulting `undefinedMethod` error and carry on — see `test/avoid_unsafe_collection_methods_test.dart`, which does exactly that. A **type**-matching rule or assist cannot, so it needs the declaration.

The general lesson: before concluding a type-based producer is broken, confirm every member the fixture calls actually resolves under `createMockSdk`.

### GOTCHA: `^` must sit at a token boundary

Marking the cursor mid-identifier (`re^duce`) does not reliably resolve to the enclosing node. Put it at the end of the method name or on the receiver (`reduce^(`, `p.flat^Map`), and check the parent-chain walk starts from a node the assist recognises.

**Reference:** [convert_iterable_map_to_collection_for_test.dart](../../../test/convert_iterable_map_to_collection_for_test.dart)

```dart
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:many_lints/src/assists/my_assist.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class MyAssistTest extends PubPackageResolutionTest {
  Future<String?> _applyAssist(String content, String target) async {
    final file = newFile('$testPackageLibPath/test.dart', content);
    final resolvedUnit = await resolveFile(file.path);
    final resolvedLibrary = await resolvedUnit.session
        .getResolvedLibraryByElement(resolvedUnit.libraryElement)
        as ResolvedLibraryResult;

    final offset = content.indexOf(target);
    final context = CorrectionProducerContext.createResolved(
      libraryResult: resolvedLibrary,
      unitResult: resolvedUnit,
      selectionOffset: offset,
      selectionLength: target.length,
    );

    final assist = MyAssist(context: context);
    final builder = ChangeBuilder(session: resolvedUnit.session);
    await assist.compute(builder);

    final change = builder.sourceChange;
    if (change.edits.isEmpty) return null;

    // Apply edits in reverse offset order
    var result = content;
    final edits = change.edits.first.edits.toList()
      ..sort((a, b) => b.offset.compareTo(a.offset));
    for (final edit in edits) {
      result = result.replaceRange(
        edit.offset, edit.offset + edit.length, edit.replacement);
    }
    return result;
  }

  Future<void> test_appliesTransformation() async {
    final result = await _applyAssist(r'...source code...', 'target');
    expect(result, contains('expected output'));
  }

  Future<void> test_notApplicable() async {
    final result = await _applyAssist(r'...source code...', 'target');
    expect(result, isNull);
  }
}
```

---

## Best Practices

### Do:

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

### Don't:

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

## Common Patterns Summary

### Pattern: Iterable Method Conversion

**Problem:** Convert `.method()` to collection-for
**Solution:**
1. Walk parent chain to find MethodInvocation
2. Check for chained `.toList()` or `.toSet()`
3. Validate with TypeChecker
4. Extract components with `.toSource()`
5. Build collection-for syntax
6. Replace using SourceRange

**Reference:** [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)

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

## Assist Implementation Checklist

1. Import required packages (analysis_server_plugin, analyzer, analyzer_plugin)
2. Import helpers if needed (type_checker, helpers)
3. Extend `ResolvedCorrectionProducer`
4. Define `static const _assistKind` with:
   - ID: `'many_lints.assist.<camelCase>'`
   - Priority: 0-100 (e.g., 30 for standard)
   - Description: Clear action label
5. Constructor: `MyAssist({required super.context})`
6. Override `applicability` -> `CorrectionApplicability.singleLocation`
7. Override `assistKind` -> return `_assistKind`
8. Implement `compute(ChangeBuilder builder)`:
   - Find target node (walk parent chain if needed)
   - Check applicability (type checks, pattern matching)
   - Return early if not applicable
   - Extract source with `.toSource()`
   - Build replacement code
   - Apply with `builder.addDartFileEdit(file, ...)`
9. Register in lib/many_lints.dart: `registerAssist(MyAssist.new)`
10. Test manually in a test project
11. Update this cookbook if you discover new patterns!

---

## Learning Path

**For new assist implementers:**

1. Read this cookbook
2. Study the example: [convert_iterable_map_to_collection_for.dart](../../../lib/src/assists/convert_iterable_map_to_collection_for.dart)
3. Understand the difference between assists and fixes
4. Practice identifying when code action should be assist vs fix
5. Use templates from this cookbook
6. Register in lib/many_lints.dart
7. Test manually
8. Update this cookbook with new patterns!

---

## Changelog

| Date | Agent/Author | Changes |
|------|-------------|---------|
| Feb 2026 | Initial creation | Extracted patterns from convert_iterable_map_to_collection_for.dart |

**Remember:** When you discover new patterns, update this document following the [Meta-Instructions](#meta-instructions-for-agents).
