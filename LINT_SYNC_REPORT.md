# Official Lint Sync Report

Generated: 2026-08-09 · Source: `pkg/linter/tool/machine/rules.json` @ `dart-lang/sdk` main
SDK rules compared: 232 stable, 5 deprecated (237 candidates; 11 experimental and 14 removed excluded) · many_lints active rules: 154

Comparison method: exact-name pass over all 154 active rule names, then a semantic pass
comparing each rule's `problemMessage` + class doc against the SDK
`description` + `details` (BAD/GOOD samples). Rules reaching a verdict of
`DUPLICATE` or `SUPERSET` had their visitor logic read in full before the
verdict was assigned.

## Summary

| Verdict | Count |
|---|---|
| DUPLICATE | 0 |
| SUPERSET | 0 |
| SUBSET | 7 |
| ADJACENT | 7 |
| WATCH | 2 |
| UNIQUE | 138 |

The removed `prefer_contains` name remains registered as a tombstone so the
analyzer can direct existing configurations to the SDK rule.

## Action required

### DUPLICATE — resolved for 1.0.0

- [x] **`prefer_contains`** → SDK **`prefer_contains`** (`stable`, since Dart 2.0, `hasFix`)
  - **Former exact name collision.** Before 1.0.0 both implementations
    registered `prefer_contains`, so enabling the SDK rule produced two
    diagnostics on the same line.
  - Ours: "Use .contains() instead of .indexOf() compared to -1."
  - SDK: "Use contains for `List` and `String` instances." — its `details` give
    the BAD sample `lunchBox.indexOf('sandwich') == -1`, the identical trigger.
  - Ours matches `indexOf(...) == -1` / `!= -1` in either operand order. The SDK
    rule covers that and is not limited to the `-1` literal comparison.
  - Rationale: same name, same intent, same trigger, and the SDK ships a fix.
    This was the one unambiguous duplicate in the package. The implementation,
    fix, test, example and rule page were removed for 1.0.0; the old docs URL
    redirects to the SDK page.

## Keep, with a documented difference

### SUBSET

- **`avoid_collection_methods_with_unrelated_types`** vs SDK
  `collection_methods_unrelated_type` — the SDK has broader conservative
  coverage, including `Queue.remove()` and additional type-parameter cases.
  Ours remains useful because `strict: true` also reports a `dynamic` argument
  passed to a collection with a known element type, a case the SDK cannot prove
  is unrelated. Its diagnostic also names both involved types. Neither rule is
  a complete replacement for the other; users should normally choose one to
  avoid duplicate diagnostics in their shared cases.

- **`avoid_unnecessary_overrides`** vs SDK `unnecessary_overrides` — the SDK
  covers methods that only invoke the corresponding `super` method. Ours also
  reports pass-through getters, setters, operator overrides and abstract
  redeclarations, while preserving the SDK's exemptions for documentation,
  non-`@override` annotations, `covariant` parameters and `noSuchMethod`.
- **`avoid_generics_shadowing`** vs SDK `avoid_shadowing_type_parameters` —
  ours flags a type parameter shadowing a **top-level declaration in the same
  file** (class, mixin, enum, typedef, extension type). The SDK rule flags a
  type parameter shadowing an **enclosing type parameter** (`class A<T> { void fn<T>() }`).
  Disjoint triggers despite near-identical names. Worth an explicit note in our
  docs page, because the names invite confusion.
- **`avoid_constant_conditions`** vs SDK `literal_only_boolean_expressions` —
  ours flags comparisons where both operands are constant *expressions*,
  including `static const` field references (`SomeClass.value == '1'`). The SDK
  rule is restricted to conditions composed only of *literals* and only in
  control-flow conditions.
- **`avoid_default_tostring`** vs SDK `avoid_type_to_string` / `no_runtimetype_tostring` —
  ours flags interpolating a value whose class has no `toString` override
  (rendering `Instance of 'Foo'`). The SDK rules target `.toString()` on a
  `Type`/`runtimeType`. Different defect entirely.
- **`avoid_unassigned_stream_subscriptions`** vs SDK `cancel_subscriptions` —
  ours flags `stream.listen(...)` used as a bare expression statement, so the
  subscription is unreachable and can never be cancelled. The SDK rule tracks
  *declared* `StreamSubscription` fields/variables that lack a `cancel()` call,
  and its own docs admit it "does not track all patterns". Ours catches the
  never-assigned case the SDK rule structurally cannot see.
- **`prefer_abstract_final_static_class`** vs SDK `avoid_classes_with_only_static_members` —
  the two give **opposite advice** on the same code: the SDK says replace the
  class with top-level members; ours says keep it and mark it `abstract final`.
  Not a duplicate, but users should not enable both. Document the conflict.

### ADJACENT — no action

`avoid_only_rethrow` (SDK `use_rethrow_when_possible` targets `throw e;`, ours
targets a catch body that is *only* `rethrow;`), `avoid_collection_equality_checks`
(SDK `unrelated_type_equality_checks` is about unrelated *types*; ours is about
collections of the same type having no deep equality), `prefer_type_over_var`
(conflicts with SDK `omit_local_variable_types`; closest analogue
`always_specify_types` is a Flutter-repo style rule the user opts into),
`prefer_align_over_container` / `prefer_padding_over_container` /
`prefer_constrained_box_over_container` / `prefer_transform_over_container`
(SDK covers only the `Color` → `ColoredBox`, `Decoration` → `DecoratedBox`,
whitespace → `SizedBox`, and empty-`Container` cases; the four parameters ours
covers are untouched by any SDK rule).

## Watch (SDK rule still experimental — no action this cycle)

- **`prefer_private_named_parameters`** — no direct SDK counterpart, but
  `use_primary_constructors` (`experimental`) moves into adjacent territory.
  Already tracked in `TODO/prefer-primary-constructors-lint.md`.
- **`prefer_type_over_var`** — SDK `var_with_no_type_annotation`
  (`experimental`) is the closest thing to a direct replacement. Re-check when
  it stabilises.

## Gaps — Flutter-category SDK rules we do not cover

Not defects; candidates for `/new-lint`. All `stable`:

| SDK rule | Description |
|---|---|
| `diagnostic_describe_all_properties` | Reference all public properties in debug methods |
| `no_logic_in_create_state` | Don't put any logic in `createState` |
| `use_full_hex_values_for_flutter_colors` | Prefer 8-digit hex for `Color` |
| `use_key_in_widget_constructors` | Use `key` in widget constructors |
| `avoid_web_libraries_in_flutter` | Avoid web-only libraries outside web plugins |
| `sized_box_shrink_expand` | Use `SizedBox.shrink`/`.expand` |
| `sort_child_properties_last` | Sort `child` last in widget creations |

Note these are all in the `flutter_lints` orbit already, so most users will
have them on. Adding our own versions would create exactly the duplication this
report exists to prevent — treat the table as coverage information, not a
backlog.

## Notes

- `flutter_lints`' `flutter.yaml` was fetched and checked: it enables SDK rules
  only and defines none of its own, so it introduces no additional collisions
  beyond those listed above.
- 138 rules have no SDK counterpart at all — the Riverpod, Bloc, hooks,
  widget-replacement, banned-* / architecture, and shorthand families are
  entirely unique to this package.
- The 17 rules added after the previous 138-rule audit were checked in both
  the exact-name and semantic passes. None duplicates a stable or deprecated
  SDK rule. In particular, `prefer_correct_json_casts` covers dynamically typed
  JSON index reads, which the SDK's `cast_nullable_to_non_nullable` cannot
  diagnose from the static type, and `avoid_passing_async_when_sync_expected`
  targets a discarded async callback rather than an `async void` declaration.
