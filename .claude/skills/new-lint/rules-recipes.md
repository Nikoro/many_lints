# Lint Rule Recipes

Copy-paste ready recipes for common lint rule patterns. For foundational patterns (rule structure, type checking, AST, visitors, reporting), see [rules-patterns.md](rules-patterns.md).

**Analyzer Version:** ^10.0.2

## Common Pattern: Parent Chain Walking

Many recipes walk up `node.parent` to find enclosing context. Always stop at function boundaries to avoid false positives from closures:

```dart
AstNode? current = node.parent;
while (current != null) {
  if (current is FunctionExpression || current is FunctionDeclaration ||
      current is MethodDeclaration) {
    return false; // Stop at function boundaries
  }
  if (current is TargetNodeType) return true;
  current = current.parent;
}
```

This pattern is used in: loop body detection, try-catch containment, lifecycle method context, widget parent checking.

## Recipes

### Check for Specific Argument Pattern

```dart
NamedExpression? findNamedArgument(InstanceCreationExpression node, String name) {
  return node.argumentList.arguments
      .whereType<NamedExpression>()
      .firstWhereOrNull((arg) => arg.name.label.name == name);
}

final alignmentArg = findNamedArgument(node, 'alignment');
if (alignmentArg != null) {
  final expr = alignmentArg.expression;
  if (expr case PrefixedIdentifier(
    prefix: SimpleIdentifier(name: 'Alignment'),
    identifier: SimpleIdentifier(name: 'center'),
  )) {
    rule.reportAtNode(node);
  }
}
```

**Ref:** [prefer_center_over_align.dart](../../../lib/src/rules/prefer_center_over_align.dart#L40-L70)

### Detect Factory Constructor Calls (with and without type args)

**With type args** (`List<int>.from(x)`): Parsed as `InstanceCreationExpression`
**Without type args** (`List.from(x)`): Parsed as `MethodInvocation`

You must register visitors for **both** node types:

```dart
registry.addInstanceCreationExpression(this, visitor);
registry.addMethodInvocation(this, visitor);
```

```dart
@override
void visitInstanceCreationExpression(InstanceCreationExpression node) {
  final name = node.constructorName.name;
  if (name == null || name.name != 'from') return;
  final typeName = node.constructorName.type.name.lexeme;
  _check(node, node.argumentList, node.staticType, typeName);
}

@override
void visitMethodInvocation(MethodInvocation node) {
  if (node.methodName.name != 'from') return;
  final target = node.target;
  if (target is! SimpleIdentifier) return;
  _check(node, node.argumentList, node.staticType, target.name);
}
```

**Ref:** [prefer_iterable_of.dart](../../../lib/src/rules/prefer_iterable_of.dart#L53-L76)

### Extract Element Type from Generic Collection

```dart
DartType? _getIterableElementType(InterfaceType type) {
  if (type.typeArguments.isNotEmpty) return type.typeArguments.first;
  for (final supertype in type.element.allSupertypes) {
    if (supertype.element.name == 'Iterable' && supertype.typeArguments.isNotEmpty) {
      return supertype.typeArguments.first;
    }
  }
  return null;
}
```

**Ref:** [prefer_iterable_of.dart](../../../lib/src/rules/prefer_iterable_of.dart#L122-L135)

### Check If Node Is Inside a Loop Body

Uses parent chain walking pattern. Check for `ForStatement`, `WhileStatement`, `DoStatement`:

```dart
static bool _isInsideLoopBody(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is ForStatement || current is WhileStatement || current is DoStatement) {
      return true;
    }
    if (current is FunctionExpression || current is FunctionDeclaration ||
        current is MethodDeclaration) {
      return false;
    }
    current = current.parent;
  }
  return false;
}
```

**Ref:** [avoid_accessing_collections_by_constant_index.dart](../../../lib/src/rules/avoid_accessing_collections_by_constant_index.dart#L57-L75)

### Check If an Identifier Refers to a Constant

Local variables resolve to `VariableElement`, top-level/static fields resolve to `PropertyAccessorElement` (synthetic getter). Handle both:

```dart
import 'package:many_lints/src/constant_expression.dart';

// Use isConstantIdentifier(id) from constant_expression.dart
// Or implement manually:
static bool _isConstantIdentifier(SimpleIdentifier id) {
  final element = id.element;
  if (element is VariableElement) {
    return element.isConst || (element.isFinal && element.computeConstantValue() != null);
  }
  if (element is PropertyAccessorElement) {
    return element.variable.isConst;
  }
  return false;
}
```

**Ref:** [avoid_accessing_collections_by_constant_index.dart](../../../lib/src/rules/avoid_accessing_collections_by_constant_index.dart#L78-L118)

### Analyze Cascade Expression Targets

```dart
@override
void visitCascadeExpression(CascadeExpression node) {
  final target = node.target;
  if (target is BinaryExpression &&
      target.operator.type == TokenType.QUESTION_QUESTION) {
    rule.reportAtNode(node);
  }
}
```

**Ref:** [avoid_cascade_after_if_null.dart](../../../lib/src/rules/avoid_cascade_after_if_null.dart#L55-L63)

### Binary Expression Analysis (Operators, Const Checks, Negative Literals)

Register `addBinaryExpression` to check operator types:

```dart
@override
void visitBinaryExpression(BinaryExpression node) {
  final op = node.operator.type;
  if (op != TokenType.EQ_EQ && op != TokenType.BANG_EQ) return;
  final leftType = node.leftOperand.staticType;
  final rightType = node.rightOperand.staticType;
  // Analyze operand types...
}
```

**Common TokenType values:** `EQ_EQ` (`==`), `BANG_EQ` (`!=`), `PLUS` (`+`), `QUESTION_QUESTION` (`??`)

**Checking for const expressions:**
```dart
static bool _isConstExpression(Expression expr) {
  var e = expr;
  while (e is ParenthesizedExpression) e = e.expression;
  return switch (e) {
    TypedLiteral(constKeyword: _?) => true,
    InstanceCreationExpression(:final keyword?) when keyword.type == Keyword.CONST => true,
    NullLiteral() => true,
    _ => false,
  };
}
```

**Detecting negative literals:** `-1` is `PrefixExpression(MINUS, IntegerLiteral(1))`, NOT `IntegerLiteral(-1)`:
```dart
static bool _isNegativeOne(Expression expr) {
  if (expr case PrefixExpression(
    operator: Token(type: TokenType.MINUS),
    operand: IntegerLiteral(value: 1),
  )) return true;
  return false;
}
```

Always check both operand orders for commutative comparisons (`x == -1` or `-1 == x`).

**Ref:** [avoid_collection_equality_checks.dart](../../../lib/src/rules/avoid_collection_equality_checks.dart#L64-L90), [prefer_contains.dart](../../../lib/src/rules/prefer_contains.dart#L68-L77)

### Check If Two Types Are Unrelated

```dart
static bool _areUnrelatedTypes(DartType argType, DartType expectedType) {
  if (argType is DynamicType || expectedType is DynamicType) return false;
  if (argType is VoidType || expectedType is VoidType) return false;
  if (argType is TypeParameterType || expectedType is TypeParameterType) return false;
  if (argType is! InterfaceType || expectedType is! InterfaceType) return false;

  return !_isSubtypeOf(argType.element, expectedType.element) &&
      !_isSubtypeOf(expectedType.element, argType.element);
}

static bool _isSubtypeOf(InterfaceElement a, InterfaceElement b) {
  if (a == b) return true;
  for (final supertype in a.allSupertypes) {
    if (supertype.element == b) return true;
  }
  return false;
}
```

**Ref:** [avoid_collection_methods_with_unrelated_types.dart](../../../lib/src/rules/avoid_collection_methods_with_unrelated_types.dart#L201-L235)

### Extract Map Key/Value Types from InterfaceType

```dart
static (DartType, DartType)? _getMapTypes(InterfaceType type) {
  if (type.element.name == 'Map' && type.typeArguments.length == 2) {
    return (type.typeArguments[0], type.typeArguments[1]);
  }
  for (final supertype in type.element.allSupertypes) {
    if (supertype.element.name == 'Map' && supertype.typeArguments.length == 2) {
      return (supertype.typeArguments[0], supertype.typeArguments[1]);
    }
  }
  return null;
}
```

**Ref:** [avoid_collection_methods_with_unrelated_types.dart](../../../lib/src/rules/avoid_collection_methods_with_unrelated_types.dart#L173-L184)

### Analyze MethodInvocation on Collection Targets

Use `node.realTarget` (not `node.target`) — `realTarget` unwraps cascade sections correctly:

```dart
@override
void visitMethodInvocation(MethodInvocation node) {
  final target = node.realTarget;
  if (target == null) return;
  final targetType = target.staticType;
  if (targetType is! InterfaceType) return;
  final methodName = node.methodName.name;
  final args = node.argumentList.arguments;
  if (args.isEmpty) return;
  final argType = args.first.staticType;
  // Check against collection type parameters...
}
```

**Ref:** [avoid_collection_methods_with_unrelated_types.dart](../../../lib/src/rules/avoid_collection_methods_with_unrelated_types.dart#L86-L143)

### Traverse Token Stream for Comment Analysis

Comments are attached to tokens via `precedingComments`, NOT as AST nodes. Use `addCompilationUnit`:

```dart
@override
void visitCompilationUnit(CompilationUnit node) {
  Token? token = node.beginToken;
  while (token != null && !token.isEof) {
    Token? comment = token.precedingComments;
    while (comment != null) {
      if (comment.type == TokenType.SINGLE_LINE_COMMENT) {
        // Process comment. Doc comments (///) are also SINGLE_LINE_COMMENT
        // — check lexeme.startsWith('///') to distinguish
      }
      comment = comment.next;
    }
    token = token.next;
  }
  // Always check EOF token's preceding comments (trailing comments at file end)
  if (token != null && token.isEof) {
    Token? comment = token.precedingComments;
    while (comment != null) { comment = comment.next; }
  }
}

// For non-AST constructs, report at offset:
rule.reportAtOffset(token.offset, token.length);
```

**Ref:** [avoid_commented_out_code.dart](../../../lib/src/rules/avoid_commented_out_code.dart#L47-L97)

### Compare Cascade Sections for Duplicates

```dart
@override
void visitCascadeExpression(CascadeExpression node) {
  final sections = node.cascadeSections;
  if (sections.length < 2) return;
  final seen = <String>{};
  for (final section in sections) {
    final key = _sectionKey(section);
    if (key == null) continue;
    if (!seen.add(key)) rule.reportAtNode(section);
  }
}

static String? _sectionKey(Expression section) {
  return switch (section) {
    AssignmentExpression(:final leftHandSide, :final rightHandSide) =>
      'assign:${leftHandSide.toSource()}=${rightHandSide.toSource()}',
    MethodInvocation(:final methodName, :final argumentList) =>
      'call:${methodName.name}(${argumentList.arguments.map((a) => a.toSource()).join(',')})',
    IndexExpression(:final index) => 'index:${index.toSource()}',
    PropertyAccess(:final propertyName) => 'prop:${propertyName.name}',
    _ => null,
  };
}
```

Cascade section types: `AssignmentExpression`, `MethodInvocation`, `IndexExpression`, `PropertyAccess`, `FunctionReference`.

**Ref:** [avoid_duplicate_cascades.dart](../../../lib/src/rules/avoid_duplicate_cascades.dart#L65-L95)

### Get Top-Level Declaration Names (Non-Deprecated API)

Different declarations use different APIs in analyzer 10.0.2:

```dart
final topLevelNames = <String>{};
for (final declaration in compilationUnit.declarations) {
  switch (declaration) {
    case ClassDeclaration(:final namePart):
      topLevelNames.add(namePart.typeName.lexeme);
    case MixinDeclaration(:final name):
      topLevelNames.add(name.lexeme);
    case EnumDeclaration(:final namePart):
      topLevelNames.add(namePart.typeName.lexeme);
    case GenericTypeAlias(:final name):
      topLevelNames.add(name.lexeme);
    case FunctionTypeAlias(:final name):
      topLevelNames.add(name.lexeme);
    case ExtensionTypeDeclaration(:final primaryConstructor):
      topLevelNames.add(primaryConstructor.typeName.lexeme);
    default: break;
  }
}
```

- `ClassDeclaration.name` / `EnumDeclaration.name` → **DEPRECATED**, use `namePart.typeName`
- `ExtensionTypeDeclaration.name` → **DEPRECATED**, use `primaryConstructor.typeName`
- `MixinDeclaration.name`, `GenericTypeAlias.name`, `FunctionTypeAlias.name` → NOT deprecated

**Ref:** [avoid_generics_shadowing.dart](../../../lib/src/rules/avoid_generics_shadowing.dart#L50-L67)

### Visit TypeParameter Declarations Across a File

Use `addCompilationUnit` + `RecursiveAstVisitor` to find all `TypeParameter` nodes:

```dart
@override
void visitCompilationUnit(CompilationUnit node) {
  // Collect context (e.g., top-level names)...
  final checker = _TypeParameterChecker(rule, topLevelNames);
  node.visitChildren(checker);
}

class _TypeParameterChecker extends RecursiveAstVisitor<void> {
  @override
  void visitTypeParameter(TypeParameter node) {
    final name = node.name.lexeme;
    // TypeParameter.parent is TypeParameterList
    // TypeParameterList.parent is the declaring scope (ClassDeclaration, etc.)
    super.visitTypeParameter(node);
  }
}
```

**Ref:** [avoid_generics_shadowing.dart](../../../lib/src/rules/avoid_generics_shadowing.dart#L78-L94)

### Analyze If-Case Patterns (Dart 3 Pattern Matching)

Register `addIfStatement`. When using if-case syntax, `caseClause` is non-null:

```dart
@override
void visitIfStatement(IfStatement node) {
  final caseClause = node.caseClause;
  if (caseClause == null) return;
  final pattern = caseClause.guardedPattern.pattern;
  final whenClause = caseClause.guardedPattern.whenClause;

  if (pattern is LogicalAndPattern) {
    final left = pattern.leftOperand;   // DartPattern
    final right = pattern.rightOperand; // DartPattern
    if (left is RelationalPattern) {
      // left.operator.lexeme → '!=', '==', '>', etc.
      // left.operand → Expression
    }
    if (right is DeclaredVariablePattern) {
      // right.keyword → Token? ('final', 'var')
      // right.type → TypeAnnotation?
      // right.name → Token
    }
  }
}
```

**Key DartPattern subtypes:** `LogicalAndPattern` (`&&`), `LogicalOrPattern` (`||`), `RelationalPattern` (`!= null`, `> 5`), `DeclaredVariablePattern` (`final field`), `NullCheckPattern` (postfix `?`), `NullAssertPattern` (postfix `!`), `ConstantPattern`, `WildcardPattern` (`_`).

**Ref:** [prefer_simpler_patterns_null_check.dart](../../../lib/src/rules/prefer_simpler_patterns_null_check.dart#L49-L68)

### Detect Property Access: PrefixedIdentifier vs PropertyAccess

When analyzing `target.property.method()`, the AST for `target.property` differs:
- **Simple** (`map.keys`): `PrefixedIdentifier` (prefix=`map`, identifier=`keys`)
- **Complex** (`maps.first.keys`): `PropertyAccess` (target=`maps.first`, propertyName=`keys`)

Handle **both**:

```dart
@override
void visitMethodInvocation(MethodInvocation node) {
  if (node.methodName.name != 'contains') return;
  final target = node.target;

  if (target case PrefixedIdentifier(
    identifier: SimpleIdentifier(name: 'keys'),
    prefix: SimpleIdentifier(staticType: final mapType?),
  ) when _mapChecker.isAssignableFromType(mapType)) {
    rule.reportAtNode(node);
    return;
  }

  if (target case PropertyAccess(
    propertyName: SimpleIdentifier(name: 'keys'),
    target: Expression(staticType: final mapType?),
  ) when _mapChecker.isAssignableFromType(mapType)) {
    rule.reportAtNode(node);
  }
}
```

In fixes, extract differently:
```dart
final String mapSource;
if (keysAccess is PrefixedIdentifier) {
  mapSource = keysAccess.prefix.toSource();
} else if (keysAccess is PropertyAccess) {
  mapSource = keysAccess.target!.toSource();
} else { return; }
```

**Ref:** [avoid_map_keys_contains.dart](../../../lib/src/rules/avoid_map_keys_contains.dart#L49-L71)

### Validate Function Call Arguments by Name and Type

```dart
@override
void visitMethodInvocation(MethodInvocation node) {
  if (node.methodName.name != 'expect') return;
  final args = node.argumentList.arguments;
  if (args.length < 2) return;
  final actualType = args[0].staticType;
  if (actualType == null || actualType is DynamicType) return;

  final matcherExpr = args[1];
  final String? matcherName;
  if (matcherExpr is SimpleIdentifier) {
    matcherName = matcherExpr.name;
  } else if (matcherExpr is MethodInvocation) {
    matcherName = matcherExpr.methodName.name;
  } else { return; }

  if (_isIncompatible(actualType, matcherName)) {
    rule.reportAtNode(matcherExpr, arguments: [matcherName, ...]);
  }
}
```

**Type category checks:**
```dart
static bool _isNullable(DartType type) =>
    type.nullabilitySuffix == NullabilitySuffix.question;

static bool _isOrSubtypeOf(InterfaceType type, String targetName) {
  if (type.element.name == targetName) return true;
  for (final supertype in type.element.allSupertypes) {
    if (supertype.element.name == targetName) return true;
  }
  return false;
}
```

**Ref:** [avoid_misused_test_matchers.dart](../../../lib/src/rules/avoid_misused_test_matchers.dart#L82-L218)

### Try-Catch Analysis

Register `addTryStatement`. Iterate `catchClauses` and inspect each `CatchClause.body`:

```dart
@override
void visitTryStatement(TryStatement node) {
  for (final catchClause in node.catchClauses) {
    final statements = catchClause.body.statements;
    if (statements.length != 1) continue;
    final statement = statements.first;
    if (statement is! ExpressionStatement) continue;
    if (statement.expression is RethrowExpression) {
      rule.reportAtNode(catchClause);
    }
  }
}
```

**For deep search inside catch blocks**, use `RecursiveAstVisitor` with function boundary stopping:

```dart
for (final catchClause in node.catchClauses) {
  final finder = _ThrowFinder(rule);
  catchClause.body.visitChildren(finder);
}

class _ThrowFinder extends RecursiveAstVisitor<void> {
  final MyRule rule;
  _ThrowFinder(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    rule.reportAtNode(node);
    super.visitThrowExpression(node);
  }

  // Stop at function boundaries:
  @override void visitFunctionExpression(FunctionExpression node) {}
  @override void visitFunctionDeclaration(FunctionDeclaration node) {}
}
```

**Key types:** `TryStatement` (body, catchClauses, finallyBlock), `CatchClause` (body, onKeyword, exceptionType, exceptionParameter, stackTraceParameter), `RethrowExpression` ≠ `ThrowExpression`.

**Ref:** [avoid_only_rethrow.dart](../../../lib/src/rules/avoid_only_rethrow.dart#L68-L82), [avoid_throw_in_catch_block.dart](../../../lib/src/rules/avoid_throw_in_catch_block.dart#L73-L95)

### Analyze Return Statements in Async Try-Catch Context

Register `addReturnStatement`. Walk parent chain for async detection and try-catch containment:

```dart
@override
void visitReturnStatement(ReturnStatement node) {
  final expression = node.expression;
  if (expression == null || expression is AwaitExpression) return;
  final type = expression.staticType;
  if (type is! InterfaceType) return;
  final name = type.element.name;
  if (name != 'Future' && name != 'FutureOr') return;
  if (!_isInsideTryCatch(node)) return;
  if (!_isEnclosingFunctionAsync(node)) return;
  rule.reportAtNode(expression);
}

static bool _isEnclosingFunctionAsync(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionExpression) return current.body.isAsynchronous;
    if (current is MethodDeclaration) return current.body.isAsynchronous;
    current = current.parent;
  }
  return false;
}

static bool _isInsideTryCatch(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionExpression || current is FunctionDeclaration ||
        current is MethodDeclaration) return false;
    if (current is TryStatement) {
      return _isDescendantOf(node, current.body) ||
          current.catchClauses.any((c) => _isDescendantOf(node, c));
    }
    current = current.parent;
  }
  return false;
}

static bool _isDescendantOf(AstNode node, AstNode ancestor) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current == ancestor) return true;
    current = current.parent;
  }
  return false;
}
```

**Ref:** [prefer_return_await.dart](../../../lib/src/rules/prefer_return_await.dart#L70-L139)

### Detect Unassigned Method Invocation Return Values

Check if return value is discarded via `node.parent is ExpressionStatement`:

```dart
@override
void visitMethodInvocation(MethodInvocation node) {
  if (node.methodName.name != 'listen') return;
  final returnType = node.staticType;
  if (returnType is! InterfaceType) return;
  if (!_isExpectedType(returnType)) return;
  if (node.parent is! ExpressionStatement) return;
  rule.reportAtNode(node);
}

static bool _isExpectedType(InterfaceType type) {
  if (type.element.name == 'StreamSubscription') {
    return type.element.library.identifier.startsWith('dart:async');
  }
  for (final supertype in type.element.allSupertypes) {
    if (supertype.element.name == 'StreamSubscription' &&
        supertype.element.library.identifier.startsWith('dart:async')) return true;
  }
  return false;
}
```

**Ref:** [avoid_unassigned_stream_subscriptions.dart](../../../lib/src/rules/avoid_unassigned_stream_subscriptions.dart#L49-L73)

### Check If Ancestor Overrides Specific Members (== and hashCode)

Walk `element.allSupertypes` using `InterfaceType.methods` and `InterfaceType.getters` (NOT `.accessors`). For current class, use AST-level `MethodDeclaration.isOperator`/`.isGetter`:

```dart
for (final supertype in element.allSupertypes) {
  if (supertype.element.name == 'Object') continue;
  final hasEqualsOp = supertype.methods.any((m) => m.name == '==' && !m.isAbstract);
  final hasHashCode = supertype.getters.any((g) => g.name == 'hashCode' && !g.isAbstract);
  if (hasEqualsOp && hasHashCode) { /* ancestor overrides equality */ }
}

// Current class via AST:
final overridesEquals = body.members.any(
  (m) => m is MethodDeclaration && m.isOperator && m.name.lexeme == '==',
);
final overridesHashCode = body.members.any(
  (m) => m is MethodDeclaration && m.isGetter && m.name.lexeme == 'hashCode',
);
```

**Ref:** [prefer_overriding_parent_equality.dart](../../../lib/src/rules/prefer_overriding_parent_equality.dart#L68-L97)

### Detect ObjectPattern in Switch/If-Case Patterns

Register `addSwitchExpression`, `addSwitchStatement`, `addIfStatement`. Walk patterns recursively:

```dart
@override
void visitSwitchExpression(SwitchExpression node) {
  for (final caseNode in node.cases) _checkPattern(caseNode.guardedPattern.pattern);
}

@override
void visitSwitchStatement(SwitchStatement node) {
  for (final member in node.members) {
    if (member is SwitchPatternCase) _checkPattern(member.guardedPattern.pattern);
  }
}

@override
void visitIfStatement(IfStatement node) {
  final caseClause = node.caseClause;
  if (caseClause == null) return;
  _checkPattern(caseClause.guardedPattern.pattern);
}

void _checkPattern(DartPattern pattern) {
  if (pattern is ObjectPattern && pattern.type.name.lexeme == 'Object' && pattern.fields.isEmpty) {
    rule.reportAtNode(pattern);
    return;
  }
  if (pattern is LogicalAndPattern) {
    _checkPattern(pattern.leftOperand);
    _checkPattern(pattern.rightOperand);
  }
  if (pattern is LogicalOrPattern) {
    _checkPattern(pattern.leftOperand);
    _checkPattern(pattern.rightOperand);
  }
}
```

No `addObjectPattern` in `RuleVisitorRegistry` — register container nodes and walk patterns manually.

**Ref:** [prefer_wildcard_pattern.dart](../../../lib/src/rules/prefer_wildcard_pattern.dart#L59-L98)

### Cross-Method Call Pairing (addListener/removeListener)

Register `addClassDeclaration`. Use `RecursiveAstVisitor` collectors to gather calls from different methods, then pair by comparing `toSource()`:

```dart
@override
void visitClassDeclaration(ClassDeclaration node) {
  final element = node.declaredFragment?.element;
  if (element == null || !_stateChecker.isSuperOf(element)) return;
  final body = node.body;
  if (body is! BlockClassBody) return;
  final methods = body.members.whereType<MethodDeclaration>();

  final disposeMethod = methods.where((m) => m.name.lexeme == 'dispose').firstOrNull;
  final removeCalls = <_ListenerCall>{};
  if (disposeMethod != null) {
    final collector = _MethodCallCollector('removeListener', stopAtFunctions: true);
    disposeMethod.body.visitChildren(collector);
    removeCalls.addAll(collector.calls);
  }

  for (final method in methods) {
    if (method.name.lexeme != 'initState') continue;
    final collector = _MethodCallCollector('addListener', stopAtFunctions: true);
    method.body.visitChildren(collector);
    for (final addCall in collector.calls) {
      if (!removeCalls.any((r) => r.targetSource == addCall.targetSource &&
          r.listenerSource == addCall.listenerSource)) {
        rule.reportAtNode(addCall.node);
      }
    }
  }
}
```

**Collector with function boundary stopping:**
```dart
class _MethodCallCollector extends RecursiveAstVisitor<void> {
  final String methodName;
  final bool stopAtFunctions;
  final List<_ListenerCall> calls = [];
  _MethodCallCollector(this.methodName, {this.stopAtFunctions = false});

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == methodName && node.argumentList.arguments.isNotEmpty) {
      calls.add(_ListenerCall(
        node: node,
        targetSource: node.realTarget?.toSource() ?? 'this',
        listenerSource: node.argumentList.arguments.first.toSource(),
      ));
    }
    super.visitMethodInvocation(node);
  }

  @override void visitFunctionExpression(FunctionExpression node) { if (stopAtFunctions) return; super.visitFunctionExpression(node); }
  @override void visitFunctionDeclaration(FunctionDeclaration node) { if (stopAtFunctions) return; super.visitFunctionDeclaration(node); }
}
```

**Ref:** [always_remove_listener.dart](../../../lib/src/rules/always_remove_listener.dart#L66-L102)

### Check If Widget Is Direct Child of Specific Parent Widget

Walk parent chain through `ListLiteral`, `NamedExpression`, `ArgumentList` to find enclosing widget:

```dart
static bool _isDirectChildOfFlex(InstanceCreationExpression node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is ListLiteral) { current = current.parent; continue; }
    if (current is NamedExpression) { current = current.parent; continue; }
    if (current is ArgumentList) {
      final parent = current.parent;
      if (parent is InstanceCreationExpression) {
        final parentElement = parent.constructorName.type.element;
        if (parentElement != null && _flexChecker.isSuperOf(parentElement)) return true;
      }
      return false;
    }
    if (current is FunctionExpression || current is FunctionDeclaration ||
        current is MethodDeclaration) return false;
    current = current.parent;
  }
  return false;
}
```

Widget parent chains: `child:` → NamedExpression → ArgumentList → InstanceCreationExpression. `children: [...]` → ListLiteral → NamedExpression → ArgumentList → InstanceCreationExpression.

**Ref:** [avoid_flexible_outside_flex.dart](../../../lib/src/rules/avoid_flexible_outside_flex.dart#L80-L119)

### Detect Wrapper Widget with Specific Child Type

Constructors without `new`/`const`/type args are parsed as `MethodInvocation`, NOT `InstanceCreationExpression`. Register **both**:

```dart
@override
void visitInstanceCreationExpression(InstanceCreationExpression node) {
  final element = node.constructorName.type.element;
  if (element == null || !_wrapperChecker.isExactly(element)) return;
  _checkChildArgument(node.argumentList, node.constructorName);
}

@override
void visitMethodInvocation(MethodInvocation node) {
  final type = node.staticType;
  if (type == null || !_wrapperChecker.isExactlyType(type)) return;
  _checkChildArgument(node.argumentList, node.methodName);
}

void _checkChildArgument(ArgumentList argumentList, AstNode reportNode) {
  for (final arg in argumentList.arguments.whereType<NamedExpression>()) {
    if (arg.name.label.name == 'child') {
      final childType = arg.expression.staticType;
      if (childType != null && _childChecker.isAssignableFromType(childType)) {
        rule.reportAtNode(reportNode);
      }
      return;
    }
  }
}
```

**Ref:** [avoid_incorrect_image_opacity.dart](../../../lib/src/rules/avoid_incorrect_image_opacity.dart#L62-L88)

### Search for Specific Identifiers Inside a Callback

Extract callback as `FunctionExpression`, search with `RecursiveAstVisitor`. Handle three forms: bare, prefixed (`context.mounted`), property access (`this.mounted`):

```dart
@override
void visitMethodInvocation(MethodInvocation node) {
  if (node.methodName.name != 'setState') return;
  final args = node.argumentList.arguments;
  if (args.isEmpty) return;
  final callback = args.first;
  if (callback is! FunctionExpression) return;
  final finder = _IdentifierFinder(rule);
  callback.body.visitChildren(finder);
}

class _IdentifierFinder extends RecursiveAstVisitor<void> {
  final MyRule rule;
  _IdentifierFinder(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'mounted') {
      // Exclude when already handled by PrefixedIdentifier/PropertyAccess
      final parent = node.parent;
      if (parent is PrefixedIdentifier && parent.identifier == node) return;
      if (parent is PropertyAccess && parent.propertyName == node) return;
      rule.reportAtNode(node);
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'mounted') rule.reportAtNode(node);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'mounted') rule.reportAtNode(node);
    super.visitPropertyAccess(node);
  }
}
```

**Ref:** [avoid_mounted_in_setstate.dart](../../../lib/src/rules/avoid_mounted_in_setstate.dart#L59-L124)

### Detect Unnecessary Overrides (Methods, Getters, Setters, Operators, Abstract)

Check `isAbstract` BEFORE `isGetter`/`isSetter` (abstract getters/setters have both flags):

```dart
void _checkMethodDeclaration(MethodDeclaration member) {
  final memberName = member.name.lexeme;

  if (member.isAbstract) { rule.reportAtNode(member, arguments: [memberName]); return; }

  if (member.isGetter) {
    if (_isUnnecessaryGetter(member, memberName)) rule.reportAtNode(member, arguments: [memberName]);
  } else if (member.isSetter) {
    if (_isUnnecessarySetter(member, memberName)) rule.reportAtNode(member, arguments: [memberName]);
  } else {
    if (_isOnlySuperCall(member, memberName)) rule.reportAtNode(member, arguments: [memberName]);
  }
}
```

**Operator overrides:** `super == other` is `BinaryExpression`, NOT `MethodInvocation`:
```dart
if (method.isOperator && expression is BinaryExpression) {
  return expression.leftOperand is SuperExpression &&
      expression.operator.lexeme == methodName &&
      _isSingleParamPassThrough(method.parameters, expression.rightOperand);
}
```

**Arg pass-through validation:**
```dart
static bool _areArgsPassThrough(FormalParameterList? params, ArgumentList args) {
  if (params == null) return args.arguments.isEmpty;
  final parameters = params.parameters;
  final arguments = args.arguments;
  if (parameters.length != arguments.length) return false;
  for (var i = 0; i < parameters.length; i++) {
    final param = parameters[i];
    final arg = arguments[i];
    final paramName = param.name?.lexeme;
    if (paramName == null) return false;
    if (arg is NamedExpression) {
      if (arg.name.label.name != paramName) return false;
      final expr = arg.expression;
      if (expr is! SimpleIdentifier || expr.name != paramName) return false;
    } else if (arg is SimpleIdentifier) {
      if (arg.name != paramName) return false;
    } else { return false; }
  }
  return true;
}
```

- `super.property` is `PropertyAccess(SuperExpression, SimpleIdentifier)`, NOT `PrefixedIdentifier`
- `FormalParameter.name` returns `Token?` — use `.lexeme` for the string

**Ref:** [avoid_unnecessary_overrides.dart](../../../lib/src/rules/avoid_unnecessary_overrides.dart#L71-L210)

### Detect Method Calls Inside Specific Lifecycle Methods

Register `addMethodInvocation`. Walk parent chain to find enclosing lifecycle method, stopping at function boundaries. For `build`, exempt closures in event handler callbacks:

```dart
static MethodDeclaration? _findEnclosingLifecycleMethod(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionExpression) return null;
    if (current is FunctionDeclaration) return null;
    if (current is MethodDeclaration) {
      final name = current.name.lexeme;
      if (_lifecycleMethods.contains(name)) return current;
      return null;
    }
    current = current.parent;
  }
  return null;
}

// Exempt closures passed as named args (event handlers like onPressed):
static bool _isInsideEventHandlerCallback(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is MethodDeclaration) return false;
    if (current is FunctionExpression) {
      if (current.parent is NamedExpression) return true;
    }
    current = current.parent;
  }
  return false;
}
```

**Ref:** [avoid_unnecessary_setstate.dart](../../../lib/src/rules/avoid_unnecessary_setstate.dart#L65-L130)

### Correlate Two Related Class Declarations (StatefulWidget + State)

Register `addCompilationUnit`. Collect classes, correlate by matching type args in extends clauses:

```dart
@override
void visitCompilationUnit(CompilationUnit node) {
  final statefulWidgets = <ClassDeclaration>[];
  final stateClasses = <ClassDeclaration>[];

  for (final declaration in node.declarations) {
    if (declaration is! ClassDeclaration) continue;
    final element = declaration.declaredFragment?.element;
    if (element == null) continue;
    if (_statefulWidgetChecker.isSuperOf(element)) statefulWidgets.add(declaration);
    else if (_stateChecker.isSuperOf(element)) stateClasses.add(declaration);
  }

  for (final widget in statefulWidgets) {
    final widgetName = widget.namePart.typeName.lexeme;
    final stateClass = _findStateClass(stateClasses, widgetName);
    if (stateClass == null) continue;
    if (_isUnnecessaryState(stateClass)) rule.reportAtToken(widget.namePart.typeName);
  }
}

static ClassDeclaration? _findStateClass(List<ClassDeclaration> stateClasses, String widgetName) {
  for (final stateClass in stateClasses) {
    final superclass = stateClass.extendsClause?.superclass;
    if (superclass == null) continue;
    final typeArgs = superclass.typeArguments?.arguments;
    if (typeArgs != null && typeArgs.length == 1) {
      final typeArg = typeArgs.first;
      if (typeArg is NamedType && typeArg.name.lexeme == widgetName) return stateClass;
    }
  }
  return null;
}
```

**Checking mutable fields:**
```dart
static bool _hasMutableFields(BlockClassBody body) {
  for (final member in body.members) {
    if (member is! FieldDeclaration) continue;
    if (member.isStatic) continue;
    final fields = member.fields;
    if (fields.isConst || fields.isFinal) continue;
    return true;
  }
  return false;
}
```

**Ref:** [avoid_unnecessary_stateful_widgets.dart](../../../lib/src/rules/avoid_unnecessary_stateful_widgets.dart#L66-L148)

### Dynamic Method Detection on Types

Check if a field's type has specific methods by walking its interface and all supertypes. Useful for detecting disposable/closeable/cancellable types without hardcoding a type list.

```dart
/// Ordered list — first match wins
static const _cleanupMethods = ['dispose', 'close', 'cancel'];

static String? _findCleanupMethod(DartType type) {
  if (type is! InterfaceType) return null;

  final allMethods = <String>{};
  for (final method in type.methods) {
    final name = method.name;
    if (name != null) allMethods.add(name);
  }
  for (final supertype in type.element.allSupertypes) {
    for (final method in supertype.methods) {
      final name = method.name;
      if (name != null) allMethods.add(name);
    }
  }

  for (final cleanup in _cleanupMethods) {
    if (allMethods.contains(cleanup)) return cleanup;
  }
  return null;
}
```

**Key API notes:**
- `InterfaceType.methods` returns `List<MethodElement>` for the type's own methods
- `InterfaceType.element.allSupertypes` returns `List<InterfaceType>` for inherited types
- `MethodElement.name` is `String?` in analyzer 10.0.2 — null-check before using
- Get a field's type from AST: `variable.declaredFragment?.element.type` (not `declaredElement`)

**Ref:** [dispose_fields.dart](../../../lib/src/rules/dispose_fields.dart)

### Walk Chained Method Calls to Find Parent Context

When a method call like `.expand(...)` is followed by `.skip(1).toList()`, the AST nests them as `MethodInvocation` targets. Walk up through the chain:

```dart
AstNode topOfChain = node;
while (topOfChain.parent is MethodInvocation) {
  final parent = topOfChain.parent! as MethodInvocation;
  if (parent.target != topOfChain) break;
  topOfChain = parent;
}
// topOfChain is now the outermost call in the chain
// topOfChain.parent is the context where the result is used
```

**When to use:** Detecting if a chained expression result (e.g., `list.expand(...).skip(1).toList()`) is used in a specific context (e.g., as the `children` argument of a widget).

**Ref:** [prefer_spacing.dart](../../../lib/src/rules/prefer_spacing.dart#L200-L205)

### Handle Both InstanceCreationExpression and MethodInvocation for Constructors

Without explicit type arguments or `const`/`new`, constructors are parsed as `MethodInvocation` (not `InstanceCreationExpression`). Use `staticType` for type checking instead of element checks:

```dart
// Instead of checking the constructor element:
void _checkWidget(DartType? staticType, ArgumentList argumentList) {
  if (staticType == null) return;
  if (!_checker.isExactlyType(staticType)) return;
  // Process argumentList...
}

// Register both visitors and delegate to shared logic:
@override
void visitInstanceCreationExpression(InstanceCreationExpression node) {
  _checkWidget(node.staticType, node.argumentList);
}

@override
void visitMethodInvocation(MethodInvocation node) {
  _checkWidget(node.staticType, node.argumentList);
}
```

**When to use:** Any rule that needs to detect widget/object construction calls reliably in both real code and test mocks.

**Ref:** [prefer_spacing.dart](../../../lib/src/rules/prefer_spacing.dart#L72-L87)

### Check Super Call Position in Lifecycle Methods

Register `addMethodDeclaration` to visit methods directly (instead of `addClassDeclaration` + member iteration). Navigate up to the class via `node.parent` (→ `BlockClassBody`) → `.parent` (→ `ClassDeclaration`):

```dart
@override
void visitMethodDeclaration(MethodDeclaration node) {
  final methodName = node.name.lexeme;
  if (!_targetMethods.contains(methodName)) return;

  // Navigate to enclosing class
  final enclosingBody = node.parent;
  if (enclosingBody is! BlockClassBody) return;
  final classDecl = enclosingBody.parent;
  if (classDecl is! ClassDeclaration) return;

  final element = classDecl.declaredFragment?.element;
  if (element == null || !_stateChecker.isSuperOf(element)) return;

  // Must have block body with statements
  final body = node.body;
  if (body is! BlockFunctionBody) return;
  final statements = body.block.statements;
  if (statements.isEmpty) return;

  // Find super.<methodName>() by index
  final superIndex = _findSuperCallIndex(statements, methodName);
  if (superIndex == -1) return;

  // Check position: first for init-like, last for cleanup-like
  if (shouldBeFirst && superIndex != 0) {
    rule.reportAtNode(statements[superIndex]);
  } else if (!shouldBeFirst && superIndex != statements.length - 1) {
    rule.reportAtNode(statements[superIndex]);
  }
}

static int _findSuperCallIndex(NodeList<Statement> stmts, String name) {
  for (var i = 0; i < stmts.length; i++) {
    if (stmts[i] case ExpressionStatement(
      expression: MethodInvocation(
        target: SuperExpression(),
        methodName: SimpleIdentifier(name: final n),
      ),
    ) when n == name) return i;
  }
  return -1;
}
```

**When to use:** Rules that validate statement ordering within specific methods (lifecycle, setup/teardown).

**Ref:** [proper_super_calls.dart](../../../lib/src/rules/proper_super_calls.dart#L70-L130)

### Detect Outer Scope Variable Usage Inside Nested Closures

Register `addMethodDeclaration`. Find a parameter of the outer method, then use nested `RecursiveAstVisitor`s to find closures that shadow the same type and check if the outer variable is referenced:

```dart
@override
void visitMethodDeclaration(MethodDeclaration node) {
  final contextParam = _findParamOfType(node.parameters?.parameters, _checker);
  if (contextParam == null) return;
  final contextName = contextParam.name?.lexeme;
  if (contextName == null) return;

  final finder = _NestedClosureFinder(rule, contextName);
  node.body.visitChildren(finder);
}

class _NestedClosureFinder extends RecursiveAstVisitor<void> {
  final MyRule rule;
  final String outerName;
  _NestedClosureFinder(this.rule, this.outerName);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    final innerParam = _findParamOfType(node.parameters?.parameters, _checker);
    if (innerParam != null) {
      final innerName = innerParam.name?.lexeme;
      if (innerName != outerName) {
        // Inner closure shadows the type but not the name — check for outer usage
        final usageFinder = _UsageFinder(rule, outerName);
        node.body.visitChildren(usageFinder);
      }
    }
    super.visitFunctionExpression(node);
  }
}

class _UsageFinder extends RecursiveAstVisitor<void> {
  final MyRule rule;
  final String name;
  _UsageFinder(this.rule, this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) rule.reportAtNode(node);
    super.visitSimpleIdentifier(node);
  }

  // Stop at nested closures that also shadow the type
  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (_hasParamOfType(node.parameters?.parameters, _checker)) return;
    super.visitFunctionExpression(node);
  }
}
```

**Resolving untyped parameters:** When closure params have no type annotation (e.g., `(_)` inferred from context), use the resolved element type:

```dart
static bool _isTargetType(FormalParameter param) {
  // Try explicit type annotation first
  if (param is SimpleFormalParameter) {
    final type = param.type?.type;
    if (type != null) return _checker.isExactlyType(type);
  }
  // Fall back to resolved element type (for untyped params)
  final element = param.declaredFragment?.element;
  if (element != null) return _checker.isExactlyType(element.type);
  return false;
}
```

**When to use:** Rules that detect incorrect variable scoping (e.g., using outer BuildContext when an inner one is available).

**Ref:** [use_closest_build_context.dart](../../../lib/src/rules/use_closest_build_context.dart#L52-L180)

### Collect Property Accesses Per Variable in a Block

Register `addBlock`. Use `RecursiveAstVisitor` to traverse statements and group property accesses by target variable. Filter to local variables/parameters using `LocalElement`:

```dart
@override
void visitBlock(Block node) {
  final collector = _PropertyAccessCollector();
  for (final statement in node.statements) {
    statement.accept(collector);
  }

  for (final entry in collector.accessesByVariable.entries) {
    final variableName = entry.key;
    final info = entry.value;
    if (info.properties.length < _minOccurrences) continue;
    if (info.targetType is! InterfaceType) continue;
    rule.reportAtNode(info.firstAccess, arguments: [...]);
  }
}

class _PropertyAccessCollector extends RecursiveAstVisitor<void> {
  final Map<String, _VariableAccessInfo> accessesByVariable = {};

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _check(node.prefix.name, node.prefix.element, node.prefix.staticType,
           node.identifier.name, node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is SimpleIdentifier) {
      _check(target.name, target.element, target.staticType,
             node.propertyName.name, node);
    }
  }

  // Stop at nested functions
  @override void visitFunctionExpression(FunctionExpression node) {}
  @override void visitFunctionDeclaration(FunctionDeclaration node) {}

  void _check(String targetName, Element? targetElement, DartType? targetType,
              String propertyName, AstNode accessNode) {
    if (targetElement is! LocalElement) return;

    // Skip assignments and method call targets
    final parent = accessNode.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == accessNode) return;
    if (parent is MethodInvocation && parent.target == accessNode) return;

    accessesByVariable
        .putIfAbsent(targetName, () => _VariableAccessInfo(targetType))
        .addAccess(propertyName, accessNode);
  }
}
```

**Key API notes:**
- `SimpleIdentifier.element` (not `.staticElement`) resolves the referenced element
- `LocalElement` is the supertype of both `LocalVariableElement` and `FormalParameterElement`
- Handle both `PrefixedIdentifier` (simple `obj.prop`) and `PropertyAccess` (chained `a.b.prop`)

**Ref:** [prefer_class_destructuring.dart](../../../lib/src/rules/prefer_class_destructuring.dart#L60-L173)

### Detect Duplicate Expressions Matching Variable Initializers

Register `addBlock`. Iterate statements in order: first check for duplicates, then collect new variable initializers. Use `toSource()` to compare expressions. Override multiple expression-type visitors in a `RecursiveAstVisitor` to check each expression, suppressing child recursion on match:

```dart
@override
void visitBlock(Block node) {
  final variables = <_VariableInfo>[];

  for (final statement in node.statements) {
    // First: check for duplicates against already-collected variables
    if (variables.isNotEmpty) {
      final finder = _DuplicateExpressionFinder(variables);
      statement.accept(finder);
      for (final match in finder.matches) {
        rule.reportAtNode(match.node, arguments: [match.variableName]);
      }
    }

    // Then: collect new final/const variable initializers
    if (statement is VariableDeclarationStatement) {
      if (!statement.variables.isFinal && !statement.variables.isConst) continue;
      for (final variable in statement.variables.variables) {
        final initializer = variable.initializer;
        if (initializer == null) continue;
        if (_isTrivialExpression(initializer)) continue;
        variables.add(_VariableInfo(
          name: variable.name.lexeme,
          initializerSource: initializer.toSource(),
        ));
      }
    }
  }
}

class _DuplicateExpressionFinder extends RecursiveAstVisitor<void> {
  final List<_VariableInfo> variables;
  final List<_DuplicateMatch> matches = [];

  _DuplicateExpressionFinder(this.variables);

  // Override per-expression-type visitors and call _checkExpression():
  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_checkExpression(node)) return; // Stop recursion on match
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_checkExpression(node)) return;
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_checkExpression(node)) return;
    super.visitMethodInvocation(node);
  }

  // ... (override all relevant expression types: InstanceCreation, Index,
  //      Binary, Conditional, ListLiteral, etc.)

  // Stop at nested function boundaries
  @override void visitFunctionExpression(FunctionExpression node) {}
  @override void visitFunctionDeclaration(FunctionDeclaration node) {}

  bool _checkExpression(Expression expression) {
    final source = expression.toSource();
    for (final variable in variables) {
      if (source == variable.initializerSource) {
        matches.add(_DuplicateMatch(node: expression, variableName: variable.name));
        return true;
      }
    }
    return false;
  }
}
```

**Key points:**
- Process statements **in order** so variables are only checked against *later* expressions
- Use `toSource()` for reliable text-based comparison (not semantic equality)
- Skip trivial expressions (identifiers, literals, negated literals) to avoid noise
- Override expression-type visitors individually (not `visitExpression`) to check at the right AST level
- Return `true` from `_checkExpression()` to suppress child recursion (avoids sub-expression matches when the whole expression already matched)

**Ref:** [use_existing_variable.dart](../../../lib/src/rules/use_existing_variable.dart#L49-L84)

### Analyze Pattern Variable Declarations (Dart 3 Destructuring)

Register `addPatternVariableDeclaration` to visit `PatternVariableDeclaration` nodes directly. These represent `final SomeClass(:value) = input;` and `final (:length) = record;` syntax.

```dart
@override
void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
  final visitor = _Visitor(this);
  registry.addPatternVariableDeclaration(this, visitor);
}

@override
void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
  final pattern = node.pattern;

  // ObjectPattern: `final SomeClass(:value) = input;`
  if (pattern is ObjectPattern) {
    final fields = pattern.fields;           // NodeList<PatternField>
    final typeName = pattern.type.name.lexeme; // e.g., "SomeClass"
    for (final field in fields) {
      final name = field.effectiveName;       // String? — the property name
      final innerPattern = field.pattern;     // DartPattern (usually DeclaredVariablePattern)
      if (innerPattern is DeclaredVariablePattern) {
        final varName = innerPattern.name.lexeme; // The bound variable name
      }
    }
  }

  // RecordPattern: `final (:length) = record;`
  if (pattern is RecordPattern) {
    final fields = pattern.fields;            // NodeList<PatternField>
    // Same field access as ObjectPattern
  }

  // Access the right-hand side expression and keyword:
  final expression = node.expression;         // Expression (e.g., `input`)
  final keyword = node.keyword;               // Token (`final` or `var`)
}
```

**Key AST types:**
- `PatternVariableDeclaration` — the full declaration (keyword + pattern + `=` + expression)
- `PatternVariableDeclarationStatement` — wraps the above + semicolon (use `addPatternVariableDeclarationStatement` if you need the statement)
- `ObjectPattern` — `SomeClass(:field1, :field2)` — has `.type` (NamedType) and `.fields` (NodeList<PatternField>)
- `RecordPattern` — `(:field1, :field2)` — has `.fields` only (no type)
- `PatternField` — a single field with `.effectiveName` (String?), `.name` (PatternFieldName?), `.pattern` (DartPattern)
- `DeclaredVariablePattern` — the variable binding inside a field, has `.name` (Token), `.keyword` (Token?), `.type` (TypeAnnotation?)

**Ref:** [avoid_single_field_destructuring.dart](../../../lib/src/rules/avoid_single_field_destructuring.dart#L55-L69)

### Track Destructurings in Block and Flag Property Accesses on Same Source

Register `addBlock`. Scan statements in order: collect `PatternVariableDeclarationStatement` entries (source name, element, destructured fields), then use a `RecursiveAstVisitor` to find subsequent property accesses on the same source variable for fields not yet destructured. Match source by element identity when possible:

```dart
@override
void visitBlock(Block node) {
  final destructurings = <_DestructuringInfo>[];

  for (final statement in node.statements) {
    // First, check property accesses against existing destructurings
    if (destructurings.isNotEmpty) {
      final finder = _PropertyAccessFinder(destructurings);
      statement.accept(finder);
      for (final match in finder.matches) {
        rule.reportAtNode(match.accessNode, arguments: [...]);
      }
    }

    // Then, collect new destructuring declarations
    if (statement is PatternVariableDeclarationStatement) {
      final decl = statement.declaration;
      final expression = decl.expression;
      if (expression is! SimpleIdentifier) continue;
      if (expression.element is! LocalElement) continue;

      final pattern = decl.pattern;
      final fields = <String>{};
      if (pattern is ObjectPattern) {
        for (final field in pattern.fields) {
          final name = field.effectiveName;
          if (name != null) fields.add(name);
        }
      }
      // ... store sourceName, sourceElement, fields
    }
  }
}

class _PropertyAccessFinder extends RecursiveAstVisitor<void> {
  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _check(node.prefix.name, node.prefix.element, node.identifier.name, node);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is SimpleIdentifier) {
      _check(target.name, target.element, node.propertyName.name, node);
    }
    super.visitPropertyAccess(node);
  }

  // Stop at nested function boundaries
  @override void visitFunctionExpression(FunctionExpression node) {}
  @override void visitFunctionDeclaration(FunctionDeclaration node) {}

  void _check(String targetName, Element? targetElement,
              String propertyName, AstNode accessNode) {
    // Match by element identity, skip assignments, skip already-destructured fields
  }
}
```

**Key points:**
- Use `expression.element` (not `.staticElement`) on `SimpleIdentifier` to get the referenced element
- Match source by element identity (`targetElement == info.sourceElement`) for reliability
- Only track `LocalElement` sources (parameters and local variables)
- Handle both `PrefixedIdentifier` (simple `obj.prop`) and `PropertyAccess` (chained access)
- `PatternField.effectiveName` returns the property name being destructured

**Ref:** [use_existing_destructuring.dart](../../../lib/src/rules/use_existing_destructuring.dart#L81-L248)

### Inspect Constructors Within a Class Declaration

Register `addClassDeclaration`. Iterate `BlockClassBody.members` for `ConstructorDeclaration` nodes. Check constructor body (non-empty `BlockFunctionBody`) and initializer list (`initializers`), excluding `SuperConstructorInvocation`:

```dart
@override
void visitClassDeclaration(ClassDeclaration node) {
  final element = node.declaredFragment?.element;
  if (element == null || !_stateChecker.isSuperOf(element)) return;

  final body = node.body;
  if (body is! BlockClassBody) return;

  for (final member in body.members) {
    if (member is! ConstructorDeclaration) continue;

    final hasBody =
        member.body is BlockFunctionBody &&
        (member.body as BlockFunctionBody).block.statements.isNotEmpty;

    // Filter out super() forwarding calls — only flag real initializers
    final hasInitializers = member.initializers.any(
      (i) => i is! SuperConstructorInvocation,
    );

    if (hasBody || hasInitializers) {
      rule.reportAtNode(member);
    }
  }
}
```

**Key types:**
- `ConstructorDeclaration.body` → `FunctionBody` (usually `BlockFunctionBody` or `EmptyFunctionBody`)
- `ConstructorDeclaration.initializers` → `NodeList<ConstructorInitializer>` — subtypes: `ConstructorFieldInitializer`, `SuperConstructorInvocation`, `RedirectingConstructorInvocation`, `AssertInitializer`
- `ConstructorDeclaration.name` → `SimpleIdentifier` (class name), `.period` → `Token?` (for named constructors)

**Ref:** [avoid_state_constructors.dart](../../../lib/src/rules/avoid_state_constructors.dart#L55-L77)

### Analyze GenericFunctionType Annotations (e.g., `Future<void> Function()`)

Register `addGenericFunctionType` to visit explicit function type annotations. Key properties:

```dart
@override
void visitGenericFunctionType(GenericFunctionType node) {
  // Skip typedef definitions (the GenericFunctionType inside a typedef is the definition itself)
  if (node.parent is GenericTypeAlias) return;

  final returnType = node.returnType;       // TypeAnnotation? (e.g., NamedType for 'Future<void>')
  final params = node.parameters;           // FormalParameterList (e.g., '()')
  final typeParams = node.typeParameters;   // TypeParameterList? (e.g., '<T>')
  final isNullable = node.question != null; // Token? for trailing '?'

  // Example: match Future<void> Function()
  if (returnType is NamedType && returnType.name.lexeme == 'Future') {
    final typeArgs = returnType.typeArguments;
    if (typeArgs != null && typeArgs.arguments.length == 1) {
      final typeArg = typeArgs.arguments.first;
      if (typeArg is NamedType && typeArg.name.lexeme == 'void') {
        if (params.parameters.isEmpty && typeParams == null) {
          rule.reportAtNode(node);
        }
      }
    }
  }
}
```

**Key notes:**
- `GenericFunctionType` represents `ReturnType Function(Params)` syntax in type annotations
- Bare `Function` (without return/params) is `NamedType`, NOT `GenericFunctionType`
- Skip `node.parent is GenericTypeAlias` to avoid flagging typedef definitions
- `node.question` is the `?` token for nullable function types like `void Function()?`
- Length of `Future<void> Function()` is **23 characters** (not 24)

**Ref:** [prefer_async_callback.dart](../../../lib/src/rules/prefer_async_callback.dart#L60-L85)

### Verify Target Resolves to a dart: SDK Class

When detecting calls like `Isolate.run()`, a user might define their own `Isolate` class. Verify the identifier resolves to the actual SDK class by checking `element.library.identifier`:

```dart
@override
void visitMethodInvocation(MethodInvocation node) {
  if (node.methodName.name != 'run') return;

  final target = node.target;
  if (target is! SimpleIdentifier) return;
  if (target.name != 'Isolate') return;

  // Verify the target resolves to dart:isolate's Isolate class
  final element = target.element;
  if (element == null) return;
  final library = element.library;
  if (library == null) return;
  if (!library.identifier.startsWith('dart:isolate')) return;

  rule.reportAtNode(node);
}
```

**Key details:**
- `SimpleIdentifier.element` resolves to the referenced element (class, function, etc.)
- `element.library.identifier` returns the library URI string (e.g., `dart:isolate`, `dart:core`, `package:flutter/...`)
- Use `startsWith('dart:isolate')` for dart: libraries
- This prevents false positives when users define their own class with the same name

**Ref:** [prefer_compute_over_isolate_run.dart](../../../lib/src/rules/prefer_compute_over_isolate_run.dart#L60-L75)

### Check If a Widget's Constructor Has a Specific Named Parameter

Use `InterfaceType.element.constructors` to dynamically check if a type's constructor accepts a particular named parameter. Useful when the rule should apply to *any* widget that supports a parameter (e.g., `padding`), not just a hardcoded list:

```dart
static bool _hasPaddingParam(InterfaceType type) {
  for (final constructor in type.element.constructors) {
    for (final param in constructor.formalParameters) {
      if (param.isNamed && param.name == 'padding') return true;
    }
  }
  return false;
}
```

**Getting type info from both InstanceCreationExpression and MethodInvocation children:**
```dart
static (String?, ArgumentList?) _getChildInfo(Expression expr) {
  if (expr is InstanceCreationExpression) {
    return (expr.constructorName.type.name.lexeme, expr.argumentList);
  }
  if (expr is MethodInvocation) {
    return (expr.methodName.name, expr.argumentList);
  }
  return (null, null);
}

// Then check the static type:
final childType = childExpr.staticType;
if (childType is! InterfaceType) return;
if (!_hasPaddingParam(childType)) return;
```

**Key API notes:**
- `InterfaceType.element.constructors` returns `List<ConstructorElement>`
- `ConstructorElement.formalParameters` returns `List<FormalParameterElement>`
- `FormalParameterElement.isNamed` and `.name` for checking named parameters
- Works for any widget/class, not just Flutter-specific types

**Ref:** [avoid_wrapping_in_padding.dart](../../../lib/src/rules/avoid_wrapping_in_padding.dart#L106-L112)

### Detect Functional List Building Patterns (map/toList, spread+map, List.generate, fold)

Register multiple visitors to detect different patterns. Key: suppress duplicate diagnostics when patterns overlap (e.g., `.map().toList()` inside a `SpreadElement`):

```dart
registry.addMethodInvocation(this, visitor);
registry.addInstanceCreationExpression(this, visitor);
registry.addListLiteral(this, visitor);

// Pattern 1: iterable.map((e) => ...).toList()
@override
void visitMethodInvocation(MethodInvocation node) {
  if (node.methodName.name == 'toList') {
    // Skip if inside a spread — Pattern 2 handles that case
    if (node.parent is SpreadElement) return;
    final target = node.target;
    if (target is! MethodInvocation) return;
    if (target.methodName.name != 'map') return;
    final args = target.argumentList.arguments;
    if (args.isEmpty || args.first is! FunctionExpression) return;
    rule.reportAtNode(node);
  }
}

// Pattern 2: [...iterable.map((e) => ...)] in list literals
@override
void visitListLiteral(ListLiteral node) {
  for (final element in node.elements) {
    if (element is SpreadElement) {
      var expr = element.expression;
      // Unwrap optional .toList()
      if (expr is MethodInvocation && expr.methodName.name == 'toList') {
        expr = expr.target!;
      }
      if (expr is! MethodInvocation || expr.methodName.name != 'map') continue;
      final args = expr.argumentList.arguments;
      if (args.isEmpty || args.first is! FunctionExpression) continue;
      rule.reportAtNode(element);
    }
  }
}

// Pattern 3: List.generate(n, (i) => ...) — MethodInvocation without type args
// Also handle List<T>.generate() as InstanceCreationExpression with type args

// Pattern 4: iterable.fold([], (list, e) { ... }) — empty list literal as first arg
```

**Key points:**
- `List.generate()` without type args → `MethodInvocation`; with type args → `InstanceCreationExpression`
- Verify `List` resolves to `dart:core` via `element.library.identifier.startsWith('dart:core')`
- Use `registry.addListLiteral` to visit `ListLiteral` nodes and inspect `SpreadElement` children
- Check `node.parent is SpreadElement` to avoid double-reporting when both patterns match

**Ref:** [prefer_for_loop_in_children.dart](../../../lib/src/rules/prefer_for_loop_in_children.dart#L43-L166)
