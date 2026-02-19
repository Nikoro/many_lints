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
- **AST helpers** (`../ast_node_analysis.dart`) — `isExpressionExactlyType()`, `maybeGetSingleReturnExpression()`, `firstWhereOrNull`, `enclosingClassDeclaration()`, `hasOverrideAnnotation()`, `negateExpression()`, `buildEveryReplacement()`
- **Hook detection** (`../hook_detection.dart`) — `getAllInnerHookExpressions()`, `maybeHookBuilderBody()`
- **String distance** (`../text_distance.dart`) — `computeEditDistance()`
- **Disposal utils** (`../disposal_utils.dart`) — `findCleanupMethod()`, `cleanupMethods` (shared by dispose_fields + dispose_provided_instances)
- **Widget helpers** (`../flutter_widget_helpers.dart`) — `FlexAxis` enum (shared by prefer_spacing + use_gap)
- **Riverpod checkers** (`../riverpod_type_checkers.dart`) — `notifierChecker` TypeChecker (shared by avoid_notifier_constructors + dispose_provided_instances)
- **Reporting** — `reportAtNode()`, `reportAtToken()`, `reportAtOffset()`, with `{0}` placeholder interpolation
- **Analyzer 10.1.0** — use `node.declaredFragment?.element` (not deprecated `.element`), `node.body` (not `.members`), `namePart.typeName` for class/enum names

## Example Rules

| Pattern | Example | Description |
|---------|---------|-------------|
| Suffix naming | [use_bloc_suffix.dart](use_bloc_suffix.dart) | Uses `ClassSuffixValidator` base class |
| Widget replacement | [prefer_center_over_align.dart](prefer_center_over_align.dart), [prefer_transform_over_container.dart](prefer_transform_over_container.dart) | Checks constructor params with `isInstanceCreationExpressionOnlyUsingParameter` |
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
| Cross-method pairing | [always_remove_listener.dart](always_remove_listener.dart) | Track addListener/removeListener across lifecycle methods using RecursiveAstVisitor collectors, `toSource()` matching |
| Dynamic method detection | [dispose_fields.dart](dispose_fields.dart) | Check if a field's type has specific methods (dispose/close/cancel) by walking `InterfaceType.methods` + `allSupertypes`, collect cleanup calls in dispose() via RecursiveAstVisitor |
| Widget hierarchy check | [avoid_flexible_outside_flex.dart](avoid_flexible_outside_flex.dart) | Walk parent chain through ListLiteral/NamedExpression/ArgumentList to find enclosing widget constructor |
| Widget wrapping check | [avoid_incorrect_image_opacity.dart](avoid_incorrect_image_opacity.dart) | Detect widget wrapping pattern (Opacity→Image), handle both InstanceCreationExpression and MethodInvocation for constructors, check child staticType |
| Callback body search | [avoid_mounted_in_setstate.dart](avoid_mounted_in_setstate.dart) | Search callback arg of MethodInvocation for identifiers (bare, prefixed, property access) using RecursiveAstVisitor |
| Super-only override | [avoid_unnecessary_overrides_in_state.dart](avoid_unnecessary_overrides_in_state.dart) | Check overridden methods in State subclasses for bodies that only call super (block and expression forms) |
| General override check | [avoid_unnecessary_overrides.dart](avoid_unnecessary_overrides.dart) | Detect unnecessary overrides in any class/mixin: super-only methods (with arg pass-through), getter/setter delegates, abstract redeclarations, operator overrides via BinaryExpression |
| Lifecycle method context | [avoid_unnecessary_setstate.dart](avoid_unnecessary_setstate.dart) | Detect method calls in specific lifecycle contexts by walking parent chain with function boundary stopping, event handler callback exemption via NamedExpression parent check |
| Multi-class correlation | [avoid_unnecessary_stateful_widgets.dart](avoid_unnecessary_stateful_widgets.dart) | Use `addCompilationUnit` to correlate two related class declarations (StatefulWidget + State) by matching type arguments in extends clauses, check mutable fields via `FieldDeclaration.isStatic`/`VariableDeclarationList.isFinal`/`isConst` |
| File-level class counting | [prefer_single_widget_per_file.dart](prefer_single_widget_per_file.dart) | Use `addCompilationUnit` to count public widget classes (skip `_`-prefixed), report 2nd+ occurrences via `reportAtToken(namePart.typeName)` |
| Multi-pattern detection | [prefer_spacing.dart](prefer_spacing.dart) | Detect SizedBox spacers via 3 patterns (direct list, `.separatedBy()`, `.expand()`), handle both `InstanceCreationExpression` and `MethodInvocation` for constructors, walk chained method calls via target parent, use `isExactlyType` on `staticType` |
| Lifecycle method ordering | [proper_super_calls.dart](proper_super_calls.dart) | Use `addMethodDeclaration` to visit methods directly, check super call position in block body via statement index, navigate `BlockClassBody.parent` to find enclosing class |
| Outer scope variable detection | [use_closest_build_context.dart](use_closest_build_context.dart) | Detect outer variable usage inside nested closures with shadowing params; resolve untyped param types via `param.declaredFragment?.element.type`; multi-level RecursiveAstVisitor (finder→usage checker) with function boundary stopping |
| Block-scoped property collection | [prefer_class_destructuring.dart](prefer_class_destructuring.dart) | Use `addBlock` + `RecursiveAstVisitor` to collect property accesses grouped by target variable; check `element is LocalElement` to filter to locals/params; skip assignment targets and method call targets |
| Expression deduplication | [use_existing_variable.dart](use_existing_variable.dart) | Use `addBlock` to scan statements in order: first check for duplicates via `toSource()` comparison against collected variable initializers, then collect new final/const variable initializers; `RecursiveAstVisitor` with per-expression-type overrides that call `_checkExpression()` and suppress child recursion on match; stop at function boundaries; skip trivial expressions (identifiers, literals) |
| Pattern variable declaration | [avoid_single_field_destructuring.dart](avoid_single_field_destructuring.dart) | Use `addPatternVariableDeclaration` to visit `PatternVariableDeclaration` nodes directly; check `pattern` for `ObjectPattern`/`RecordPattern` with `fields.length == 1`; access field name via `PatternField.effectiveName`, variable name via `DeclaredVariablePattern.name.lexeme` |
| Destructuring + property access | [use_existing_destructuring.dart](use_existing_destructuring.dart) | Use `addBlock` to scan statements: collect `PatternVariableDeclarationStatement` entries (source name, element, destructured fields), then find subsequent property accesses on the same source variable for fields NOT yet destructured; match by element identity; handle both `PrefixedIdentifier` and `PropertyAccess`; only tracks `LocalElement` sources |
| Named constructor detection | [avoid_border_all.dart](avoid_border_all.dart) | Detect `ClassName.namedCtor()` calls via both `InstanceCreationExpression` (with type args) and `MethodInvocation` (without); use `staticType` + `TypeChecker.isExactlyType()` for type verification |
| Widget wrapping with empty child | [avoid_expanded_as_spacer.dart](avoid_expanded_as_spacer.dart) | Detect wrapper widget with empty child (no args or only `key`); shared `_check()` for both `InstanceCreationExpression` and `MethodInvocation`; child arg inspection via `staticType` |
| Return type checking | [avoid_returning_widgets.dart](avoid_returning_widgets.dart) | Use `addMethodDeclaration` + `addFunctionDeclaration` to check return types; `returnType.type` → `InterfaceType` check + `TypeChecker.isAssignableFromType()`; exempt specific method names (e.g., `build`) |
| Constructor inspection | [avoid_state_constructors.dart](avoid_state_constructors.dart) | Use `addClassDeclaration` to find `ConstructorDeclaration` members; check `body is BlockFunctionBody` with non-empty statements + `initializers.any()` (filter out `SuperConstructorInvocation`); type-check enclosing class with `TypeChecker.isSuperOf()` |
| GenericFunctionType analysis | [prefer_async_callback.dart](prefer_async_callback.dart) | Use `addGenericFunctionType` to visit explicit function type annotations; check `returnType`, `parameters`, `typeParameters`, `question`; skip `node.parent is GenericTypeAlias` for typedef definitions |
| dart: library verification | [prefer_compute_over_isolate_run.dart](prefer_compute_over_isolate_run.dart) | Verify `SimpleIdentifier` resolves to a dart: SDK class via `element.library.identifier.startsWith('dart:isolate')` to avoid false positives on user-defined classes with the same name |
| Constructor param check | [avoid_wrapping_in_padding.dart](avoid_wrapping_in_padding.dart) | Dynamically check if a type's constructor has a specific named parameter via `InterfaceType.element.constructors` → `formalParameters` → `isNamed && name == 'padding'`; handles both `InstanceCreationExpression` and `MethodInvocation` children |
| Constructor optimization | [prefer_correct_edge_insets_constructor.dart](prefer_correct_edge_insets_constructor.dart) | Analyze constructor arguments via `toSource()` comparison to suggest simpler constructors; handle named args with `NamedExpression`, positional args by index; `reportAtNode` with `{0}` placeholder for suggestion message |
| Multi-pattern detection (spread/map/generate/fold) | [prefer_for_loop_in_children.dart](prefer_for_loop_in_children.dart) | Register `addMethodInvocation` + `addInstanceCreationExpression` + `addListLiteral`; detect `.map().toList()`, `...list.map()`, `List.generate()`, `.fold([],...)` patterns; suppress duplicate diagnostics when patterns overlap (e.g., skip `.toList()` inside `SpreadElement`) |
| Build return type naming | [use_sliver_prefix.dart](use_sliver_prefix.dart) | Use `addCompilationUnit` to correlate StatefulWidget + State; check if `build()` returns a type whose class name starts with 'Sliver' from `package:flutter/`; uses `maybeGetSingleReturnExpression()` + `InterfaceType.element.name` + library URI check; name-based heuristic since Flutter has no common sliver supertype |
| Class member restriction | [avoid_bloc_public_methods.dart](avoid_bloc_public_methods.dart) | Use `addClassDeclaration` + `TypeChecker.isSuperOf()` to find Bloc subclasses; iterate `BlockClassBody.members` for `MethodDeclaration`; skip private (`_`-prefix), static, and `@override` members; exclude Cubit subclasses via separate `TypeChecker` |
| Param type restriction | [avoid_passing_build_context_to_blocs.dart](avoid_passing_build_context_to_blocs.dart) | Use `addClassDeclaration` + `TypeChecker.isSuperOf()` to find Bloc/Cubit subclasses; iterate constructor and method parameters; check `param.declaredFragment?.element.type` against `TypeChecker.isExactlyType()` for forbidden types |
| Static method replacement | [prefer_bloc_extensions.dart](prefer_bloc_extensions.dart) | Detect `ClassName.of(context)` via `addMethodInvocation`; check `node.target is SimpleIdentifier` + name match; verify library via `element.library.identifier`; check named args for `listen: true` via `BooleanLiteral` pattern match |
| Annotation check + hierarchy | [prefer_immutable_bloc_state.dart](prefer_immutable_bloc_state.dart) | Use `addCompilationUnit` for two-strategy detection: (1) extract state type parameter from Bloc/Cubit extends clause, (2) name pattern (`*State`); propagate through extends/implements hierarchy with fixed-point loop; check `@immutable` annotation via `metadata` |
| Nested widget flattening | [prefer_multi_bloc_provider.dart](prefer_multi_bloc_provider.dart) | Register both `addInstanceCreationExpression` + `addMethodInvocation`; use `staticType` + `TypeChecker.isExactlyType()` for matching (handles constructors parsed as MethodInvocation); check `child:` arg's staticType matches same provider type; skip inner providers via parent chain check to report only outermost |
| Identifier usage in lifecycle | [avoid_ref_inside_state_dispose.dart](avoid_ref_inside_state_dispose.dart) | Use `addMethodDeclaration` to visit `dispose()` directly; navigate `BlockClassBody.parent` → `ClassDeclaration`; `TypeChecker.any()` for `ConsumerState`/`HookConsumerState`; `RecursiveAstVisitor` to find `ref` usage (method calls, prefixed identifiers, property access) with function boundary stopping |
| Specific method call in build | [avoid_ref_read_inside_build.dart](avoid_ref_read_inside_build.dart) | Use `addMethodDeclaration` to visit `build()` in ConsumerWidget/ConsumerState + Hook variants; `RecursiveAstVisitor` to find `ref.read()` calls (MethodInvocation with SimpleIdentifier target); function boundary stopping to skip closures (event handlers) |
| Provider callback analysis | [dispose_provided_instances.dart](dispose_provided_instances.dart) | Detect disposable instances in Riverpod Provider callbacks + Notifier `build()` missing `ref.onDispose()`; register both `addInstanceCreationExpression` + `addMethodInvocation` for Provider construction detection (type args vs no type args); check `staticType` against provider type name set; `_DisposableVariableFinder` collects vars with cleanup methods, `_OnDisposeCollector` tracks `ref.onDispose()` calls (tear-off, lambda, block forms) |
| Async gap ref/state guard | [use_ref_and_state_synchronously.dart](use_ref_and_state_synchronously.dart) | Use `addMethodDeclaration` to visit async methods in Notifier/AsyncNotifier classes; sequential statement scan tracks "seen await" flag; `_AwaitFinder` + `_RefStateFinder` RecursiveAstVisitors with function boundary stopping; detect mounted guard pattern (`if (!ref.mounted) return;`) to reset await tracking; finds ref/state via MethodInvocation, PrefixedIdentifier, SimpleIdentifier, AssignmentExpression, PropertyAccess |

## Updating Documentation

When discovering new patterns while implementing rules:
1. Add a **brief mention** to this file (table row or bullet point)
2. Add **full details** to the cookbook files in `.claude/skills/new-lint/`
