# Official Lint Sync Report

Generated: 2026-08-17 · Source: [dart.dev/tools/linter-rules](https://dart.dev/tools/linter-rules), Dart 3.13.0
SDK rules compared: 232 stable, 6 deprecated (238 candidates; 12 experimental and 14 removed excluded) · many_lints active rules: 251

Comparison method: brace-matched extraction of all 251 active `LintCode` declarations,
an exact-name pass, then a semantic pass over each rule's message and class
documentation. The machine-readable `rules.json` endpoint returned HTTP 429
for both `main` and `stable`, so this run used the official Dart 3.13 rendered
catalog as the documented degraded fallback. The individual official detail
pages and our complete visitor implementations were read before either
`SUPERSET` verdict was assigned.

## Summary

| Verdict | Count |
|---|---|
| DUPLICATE | 0 |
| SUPERSET | 0 |
| SUBSET | 8 |
| ADJACENT | 13 |
| WATCH | 2 |
| UNIQUE | 228 |

The removed `prefer_contains` and `avoid_unnecessary_overrides_in_state` names
remain registered as tombstones so the analyzer can direct existing
configurations to the SDK rules.

## Resolved for 1.0.0

- [x] **`prefer_named_boolean_parameters`** → SDK
  **[`avoid_positional_boolean_parameters`](https://dart.dev/tools/linter-rules/avoid_positional_boolean_parameters)**
  (`stable`)
  - Ours: "The boolean parameter '{0}' is positional."
  - SDK: "Avoid positional boolean parameters."
  - The triggers and rationale are the same. The SDK rule is broader: its
    documented bad examples include a single positional boolean, while ours
    permits one by default through `allow_single: true`.
  - Removed before publication. Its former docs URL redirects to the official
    SDK rule.

- [x] **`avoid_unnecessary_overrides_in_state`** → SDK
  **[`unnecessary_overrides`](https://dart.dev/tools/linter-rules/unnecessary_overrides)**
  (`stable`, in `core`, `hasFix`)
  - Ours: "This method override only calls super.{0}() without additional logic."
  - SDK: "Don't override a method to do a super method invocation with the same parameters."
  - Every intended State lifecycle case is an ordinary no-argument
    pass-through override and is already covered by the SDK. Our own broader
    `avoid_unnecessary_overrides` also reports the same nodes, so enabling the
    `opinionated` preset previously produced two many_lints diagnostics before
    the SDK diagnostic was even considered.
  - Unlike both broader rules, the State-specific visitor did not preserve the
    legitimate documentation, annotation, `covariant`, and `noSuchMethod`
    exemptions. It added false-positive surface, not useful coverage.
  - Removed for 1.0.0. Its registered tombstone and former docs URL direct
    existing users to the official SDK rule.

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

- **`member_ordering`** vs SDK `sort_constructors_first` — our configurable
  rule additionally orders fields, accessors, methods, factories, overrides,
  and Flutter `build`. With its default constructor-first order, however, the
  two rules report the same misplaced constructor. Users should choose
  `member_ordering` or the narrower SDK rule, not enable both.

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
covers are untouched by any SDK rule), `prefer_correct_future_return_type`
(an imprecise declared return type, not a missing `await`),
`avoid_passing_async_when_sync_expected` (an async closure accepted by a
sync-void parameter, not an `async void` declaration), `avoid_future_ignore`
(intentional error suppression through `Future.ignore()`, not an unawaited
future), `prefer_declaring_const_constructor` (makes a constructor const while
excluding the immutable case the SDK owns), `no_equal_switch_case` (equal case
bodies rather than duplicate case values), and `parameters_ordering`
(alphabetical ordering within required/optional groups; the SDK separately
owns required-before-optional placement).

### Resolved 2026-08-13 (Dart 3.13)

- **`prefer_primary_constructors`** vs the six lints Dart 3.13 added. Checked
  empirically, not from the docs: the SDK's `use_declaring_parameters` visits
  `PrimaryConstructorDeclaration` nodes **only**, so it never fires on a class
  that has yet to adopt one — it polishes already-migrated classes, while ours
  suggests migrating. No overlap.

  `unnecessary_type_name_in_constructor` *does* fire on the same legacy
  classes, but suggests the weaker `new(this.x)` form rather than collapsing
  the class; our docs page tells users adopting our rule to turn that one off.
  `prefer_private_named_parameters` remains without a direct SDK counterpart.

## Watch (SDK rule still experimental — no action this cycle)

- **`prefer_type_over_var`** — SDK `var_with_no_type_annotation`
  (`experimental`) is the closest thing to a direct replacement. Re-check when
  it stabilises.
- **`avoid_redundant_async`** — SDK `unnecessary_async` (`experimental`) has
  the same core goal. Ours applies stricter return-compatibility checks before
  suggesting removal; re-evaluate both visitors if the SDK rule stabilises.

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

- GitHub rate-limited the current `flutter_lints/flutter.yaml` fetch. The
  locally cached 6.0.0 file still only enables SDK rules and defines none of
  its own; the official Dart 3.13 catalog's Flutter-set markers were used for
  the reverse coverage check. Re-run from `rules.json` before release if the
  rate limit clears.
- 228 rules have no SDK counterpart at all — the Riverpod, Bloc, hooks,
  widget-replacement, banned-* / architecture, and shorthand families are
  entirely unique to this package.
- There are no exact-name collisions among the 253 active source rules. The
  removed `prefer_contains` tombstone intentionally keeps its former name so
  old configurations receive migration guidance.
