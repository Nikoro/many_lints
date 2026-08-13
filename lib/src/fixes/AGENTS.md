# Quick Fixes — Quick Reference

This directory contains quick fix implementations. Each fix extends `ResolvedCorrectionProducer` and is registered for a specific `LintCode`.

**Full implementation guide:** [fixes-cookbook.md](../../../.agents/skills/new-lint/fixes-cookbook.md)
**To create a new lint with fix:** use the `/new-lint` skill

**Testing:** every registered fix has output tests. New batches live under
`test/fix_output/`; a few older batches remain in
`test/plugin_fix_output_test.dart`. Both use `test/fix_harness.dart` (a real
`PluginServer` answering `edit.getFixes`, whose edit is applied to the source
and compared). `analyzer_testing` has no fix test API — do not conclude fixes
are untestable. See
[Testing a Fix](../../../.agents/skills/new-lint/fixes-cookbook.md#testing-a-fix).

## Fix Pattern

Concrete fixes generally follow: `ResolvedCorrectionProducer` + `FixKind` + `compute(ChangeBuilder builder)` + `builder.addDartFileEdit(file, ...)`.

- **FixKind ID:** `'many_lints.fix.<camelCase>'`
- **Priority:** Default to `DartFixKindPriority.standard`
- **Applicability:** Default to `CorrectionApplicability.singleLocation`
- **Constructor:** `MyFix({required super.context})`

## Shared helpers — reach for these before hand-rolling

- `resolveWidgetCall(node)` (`../ast_node_analysis.dart`) — resolves a reported
  node into `({Expression node, ArgumentList argumentList})` for **both** widget
  call shapes (`ConstructorName`→`InstanceCreationExpression` and
  `SimpleIdentifier`→`MethodInvocation`). Use it whenever the fix replaces the
  *whole call*.
  - ⚠️ **Not** for a fix that replaces only the `ConstructorName` (e.g.
    `prefer_center_over_align_fix`, `prefer_padding_over_container_fix`): a
    `MethodInvocation` has no node with that range, so accepting it would widen
    the replaced range. Those fixes keep their own `ConstructorName`-only guard
    on purpose — do not "unify" them.
- `indentOf(content, offset)` and `enclosingOfType<T>(node)`
  (`../ast_node_analysis.dart`) — for synthesising a line-aligned insertion.
  `enclosingOfType` starts at `node` itself, unlike `enclosingClassDeclaration`.
- `namedArgumentNode()` / `namedArgumentValue()` — exact-name argument lookup.
- `findSuperDisposeCall()` / `insertIntoDisposeMethod()`
  (`../dispose_method_editing.dart`) — insert a statement into an existing
  `dispose()` or synthesise the whole override. Shared by `dispose_fields_fix`
  and `always_remove_listener_fix`.
- `InsertGuardBeforeStatementFix` (`insert_guard_before_statement_fix.dart`) —
  base class for the "use X synchronously" fixes; a subclass supplies only
  `guardSource` and its own `fixKind`.
- `SetStateCollector` (`../set_state_collection.dart`) — shared with the rule.

**When two fixes differ only in their `FixKind` and one literal, subclass
instead of copying.** Existing pairs: `AvoidUnnecessaryOverridesInStateFix
extends AvoidUnnecessaryOverridesFix`, `PreferShorthandsWithConstructorsFix
extends PreferReturningShorthandsFix`, `PreferShorthandsWithStaticFieldsFix
extends PreferShorthandsWithEnumsFix`. Each subclass keeps its **own** fix ID —
those are public surface and must never be merged.

## Do not assume the shape of `node`

`node` comes from `nodeCovering(offset, length)`, which returns the **deepest**
node with the diagnostic's range. An unnamed `Foo(...)` therefore gives
`NamedType`, not `ConstructorName`; a `reportAtToken` on a class name gives a
name-part wrapper, not `ClassDeclaration`. `node.parent` is just as fragile.

```dart
final targetNode = node.thisOrAncestorOfType<ConstructorName>(); // ✔
if (targetNode == null) return;
```

Direct type-tests are reserved for rules that deliberately report the whole
semantic node and have output tests locking that exact range contract. Prefer
ancestor lookup for new fixes.

Getting this wrong produces no error and no exception — the fix is offered and
does nothing. It silently broke 27 fixes at once; only output tests caught it.

## Common Patterns

```dart
// Replace an entire node
builder.addSimpleReplacement(range.node(targetNode), 'NewText');

// Delete from argument list (handles commas)
builder.addDeletion(range.nodeInList(list, element));

// Replace prefix only
builder.addSimpleReplacement(range.startStart(node, parent.argumentList), 'Prefix.');

// Find named argument (analyzer 13+: NamedArgument, name is a Token)
final arg = arguments.whereType<NamedArgument>()
    .firstWhereOrNull((e) => e.name.lexeme == 'alignment');
// Value expression of any Argument (positional or named)
final value = arg.argumentExpression;
```

## Fix Inheritance (DRY patterns from audit)

- `PreferShorthandsWithConstructorsFix` extends `PreferReturningShorthandsFix` — overrides only `unnamedConstructorReplacement` getter
- `PreferShorthandsWithStaticFieldsFix` extends `PreferShorthandsWithEnumsFix` — overrides only `fixKind`
- Disposal fixes share `findCleanupMethod()` from `lib/src/disposal_utils.dart`

## Example Fixes

| Pattern | Example | Description |
|---------|---------|-------------|
| Simple replacement | [prefer_center_over_align_fix.dart](prefer_center_over_align_fix.dart) | Replace widget + delete argument |
| Multiple edits | [avoid_unnecessary_consumer_widgets_fix.dart](avoid_unnecessary_consumer_widgets_fix.dart) | Replace superclass + remove parameter |
| Complex transform | [prefer_switch_expression_fix.dart](prefer_switch_expression_fix.dart) | Switch statement → expression |
| Config-driven affix | [add_affix_fix.dart](add_affix_fix.dart) | Re-resolves `many_lints.yaml` from `unitResult.session.analysisContext.contextRoot.root` to learn the affix, since it is not known at registration time |
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
| Add annotation + import | [prefer_immutable_bloc_state_fix.dart](prefer_immutable_bloc_state_fix.dart) | Navigate from `SimpleIdentifier` to parent `ClassDeclaration`; `addSimpleInsertion` at `classDecl.offset` for `@immutable\n`; `importLibrary(Uri.parse('package:meta/meta.dart'))` to auto-add import |
| Flatten nested widgets | [prefer_multi_bloc_provider_fix.dart](prefer_multi_bloc_provider_fix.dart) | Collect consecutive nested provider calls by walking `child:` args; handle both `ConstructorName` and `SimpleIdentifier` report nodes; build Multi* wrapper with `providers: [...]` array; strip `child:` arg from each provider via `toSource()` filtering |
| Insert after statement | [dispose_provided_instances_fix.dart](dispose_provided_instances_fix.dart) | Walk up to `VariableDeclaration` then enclosing `Statement`; insert `ref.onDispose(...)` after variable declaration via `addSimpleInsertion(statement.end, ...)`; preserve indentation by scanning `unitResult.content` for line start; re-derive cleanup method from field type |
| Insert guard before statement | [use_ref_and_state_synchronously_fix.dart](use_ref_and_state_synchronously_fix.dart) | Walk up from reported node to enclosing `Statement`; compute indentation from `unitResult.content`; `addSimpleInsertion` at statement offset to insert `if (!ref.mounted) return;\n` before the flagged line |
| Insert mounted guard | [use_ref_read_synchronously_fix.dart](use_ref_read_synchronously_fix.dart) | Same pattern as above but inserts `if (!mounted) return;\n` for ConsumerWidget/ConsumerState context |
| Append to list literal | [list_all_equatable_fields_fix.dart](list_all_equatable_fields_fix.dart) | Find list literal in `props` getter (expression or block body); collect existing elements via `toSource()`; append missing field names; replace entire `ListLiteral` node |
| Extends→mixin swap | [prefer_equatable_mixin_fix.dart](prefer_equatable_mixin_fix.dart) | Replace `extends Equatable` with `with EquatableMixin`; handle existing `with` clause (delete extends + append to mixins) vs no `with` clause (simple replacement); `range.startStart()` for partial deletion |
| Unwrap factory return | [prefer_use_callback_fix.dart](prefer_use_callback_fix.dart) | Extract inner expression from `useMemoized(() => expr)` factory; rebuild as `useCallback(expr, keys)` preserving remaining args via `toSource()` |
| Offset-based rename | [prefer_use_prefix_fix.dart](prefer_use_prefix_fix.dart) | Use `diagnosticOffset`/`diagnosticLength` + `unitResult.content.substring()` to read the token text; compute new name with `use` prefix; `SourceRange` replacement |
| Collapse a class into its header | [prefer_primary_constructors_fix.dart](prefer_primary_constructors_fix.dart) | Rewrite `namePart` **and** body in **one** `range.startEnd(namePart, body)` replacement — editing them as two edits leaves the whitespace between header and `{` behind, yielding `class Point(...) ;`. `const` moves from the constructor onto the header, where the spelling is `class const Point(...)` (verified const-constructible; five other guesses do not compile). Emit parameters in the **constructor's** order, never the field declaration order, or positional call sites silently break. Declines on a doc-commented or annotated field, since neither has a home in a parameter list |
| Parameter rewrite + initializer removal | [prefer_private_named_parameters_fix.dart](prefer_private_named_parameters_fix.dart) | Rebuild a `RegularFormalParameter` as `this._field` preserving `required`/`defaultClause`; replace from `SyntacticEntity` start (`requiredKeyword ?? type ?? name`) to keep metadata; delete lone initializer via `range.endEnd(constructor.parameters, initializer)` or `range.nodeInList` when several |
| Comparison → getter | [prefer_theme_mode_getters_fix.dart](prefer_theme_mode_getters_fix.dart) | Replace whole `BinaryExpression` with `target.isX` / `!target.isX`; parenthesize non-trivial targets before appending the getter |
| Wrap argument + import | [missing_provider_scope_fix.dart](missing_provider_scope_fix.dart) | Wrap `runApp`'s first arg via two `addSimpleInsertion` calls (prefix at `offset`, `)` at `end`); pick an already-imported Riverpod library with `builder.importsLibrary(uri)` before falling back to `importLibraryElement`, and honour the returned `prefix` |
| Token deletion + insertion | [async_value_nullable_pattern_fix.dart](async_value_nullable_pattern_fix.dart) | Delete the `?` with `range.token(node.operator)` and insert `, hasValue: true` at `operator.end` |
| Insert member into class | [notifier_build_fix.dart](notifier_build_fix.dart) | `node.thisOrAncestorOfType<ClassDeclaration>()` from the reported name token, then `addSimpleInsertion(body.leftBracket.end, ...)` to add a stub method |
| Merge two statements | [avoid_collapsible_if_fix.dart](avoid_collapsible_if_fix.dart) | Two edits: replace the outer condition with `a && b`, then replace the outer then-branch with the inner one's body; parenthesise an operand whose own operator (`\|\|`, ternary) binds looser than `&&` |
| Hoist block to outer scope | [avoid_redundant_else_fix.dart](avoid_redundant_else_fix.dart) | `range.endEnd(thenStatement, elseStatement)` to drop the `else` wrapper and re-emit its statements; refuse when the body contains a `VariableDeclarationStatement`, since hoisting could collide with a name in the enclosing scope |
| Collapse statement pair | [prefer_immediate_return_fix.dart](prefer_immediate_return_fix.dart) | `range.startEnd(declaration, returnStatement)` replaced by a single `return <initializer>;` |
| Loop → single call | [prefer_add_all_fix.dart](prefer_add_all_fix.dart) | Rebuild `target.addAll(source)` from the `ForEachPartsWithDeclaration.iterable` and the `add` call's `realTarget` |
| Collapse a statement run | [prefer_add_all_fix.dart](prefer_add_all_fix.dart) | Second shape of the same fix: the rule reports the run's *second* call, so re-derive the run from the enclosing `Block` (walk back and forward while the receiver matches), then `range.startEnd(first, last)` to replace all of them with one call |
| Delete duplicate element | [avoid_duplicate_collection_elements_fix.dart](avoid_duplicate_collection_elements_fix.dart) | Walk up to the child of the enclosing literal so one lookup works for `Expression`, `SpreadElement` and `IfElement` alike; `range.nodeInList` takes the separating comma |
| Withhold an unsafe rename | [never_discard_build_context_fix.dart](never_discard_build_context_fix.dart) | A fix may return without editing: renaming a wildcard to `context` is only safe when nothing in scope already binds that name, so scan the **outermost** enclosing member (`MethodDeclaration` ?? `FunctionDeclaration` ?? `FunctionBody`) for a colliding declaration and bail. Over-approximating costs an offered fix; missing a collision silently rebinds a name the body already reads. `FixHarness.applyFix` throws a `TestFailure` when no fix is offered — assert that with `expectLater(..., throwsA(isA<TestFailure>()))` |
| Delete a member's own lines | [prefer_abstract_final_static_class_fix.dart](prefer_abstract_final_static_class_fix.dart) | Line-boundary deletion that consumes the *trailing* blank line, not the preceding one — unlike `avoid_unnecessary_overrides_fix`, whose target is never the first member. Removing a leading constructor with that fix's range would eat the line holding the class's opening brace |
| Drop a default-valued argument | [avoid_shrink_wrap_in_lists_fix.dart](avoid_shrink_wrap_in_lists_fix.dart) | Deleting a named argument is only behaviour-preserving when the parameter's default equals the removed value — verify that before reaching for this pattern; `range.nodeInList(argumentList.arguments, arg)` handles the comma |
| Substitute a value for a lambda parameter | [prefer_from_predicate_fix.dart](prefer_from_predicate_fix.dart) | Rewriting `cond ? Some(v) : None()` into `fromPredicate(v, (p) => cond)` means replacing every occurrence of the value inside the condition. Collect the occurrence ranges first and splice back-to-front against `unitResult.content`, or earlier replacements shift later offsets. Pick the parameter name by collecting **every** identifier in the expression and avoiding all of them — the naive first initial silently shadows a name the condition already reads |
| Deliberately non-file-wide | [prefer_safe_collection_access_fix.dart](prefer_safe_collection_access_fix.dart) | `CorrectionApplicability.singleLocation` is the right choice when the edit **changes the expression's type** (`first` → `head` turns `T` into `Option<T>`). Every use site needs a follow-up, so applying in bulk would leave a file of type errors. A name the rule accepts via config but the fix has no counterpart for simply returns without editing — warn without fixing beats guessing |
| Rewrite to an extension getter | [prefer_string_parse_extensions_fix.dart](prefer_string_parse_extensions_fix.dart) | Turning `f(x)` into `x.getter` moves the receiver into `.`-position, so an operand that binds looser than `.` (`a ?? b`, a ternary, a cascade) must be parenthesised or the result parses as something else entirely. Whitelist the shapes that are safe bare (identifier, property access, prefixed identifier, invocation, simple string, index) and wrap everything else |
| Collapse a conditional | [prefer_from_nullable_fix.dart](prefer_from_nullable_fix.dart) | Re-derive the kept operand from the AST rather than parsing it out of the diagnostic message, so rewording the rule cannot break the fix; `range.node(conditional)` replaces both branches at once |
| Type-argument swap + import | [prefer_unit_over_void_fix.dart](prefer_unit_over_void_fix.dart) | Replace the reported `NamedType` only (`range.node`), never the enclosing one, or the sibling type arguments are silently dropped; `builder.importLibrary(Uri.parse(...))` is a no-op when the import is already present, so no `importsLibrary` guard is needed. Deliberately stops at the annotation and leaves the now-required `return unit;` to the author — a fix that rewrites control flow to satisfy a type is not one to apply unread. Its test needs `FixHarness.applyFix(multiFilePackages: ...)`, since `packages` writes only `lib/<name>.dart` and the fpdart checkers pin declaring libraries |

## Updating Documentation

When discovering new patterns while implementing fixes:
1. Add a **brief mention** to this file (table row or bullet point)
2. Add **full details** to [fixes-cookbook.md](../../../.agents/skills/new-lint/fixes-cookbook.md)
