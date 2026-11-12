# Official Lint Sync Report

Generated: 2026-11-12 · Source: [`pkg/linter/tool/machine/rules.json`](https://github.com/dart-lang/sdk/blob/3.14.0/pkg/linter/tool/machine/rules.json) @ tag `3.14.0` (commit `fa8c1270c374c1346931583a17c3b7f278d3822d`)
SDK rules compared: 233 stable, 6 deprecated (239 candidates; 11 experimental and 14 removed excluded) · many_lints active rules: 264

Comparison method: brace-matched extraction of all 264 `LintCode` declarations
(one per rule file, count asserted), an exact-name pass against every name in
the 3.14.0 file, then a semantic pass. Rules unchanged since the
2026-08-18 report (source `a51710497d`) keep their verdicts; the 13 rules added
in 1.1.0 to 1.3.0 and every SDK change between that source and the 3.14.0 tag
were classified fresh. The released SDK tag is the source, not `main`, because
this report backs a release. The current
[`flutter_lints/flutter.yaml`](https://github.com/flutter/packages/blob/main/packages/flutter_lints/lib/flutter.yaml)
still only enables SDK rules.

## What changed in the SDK since the last report

Between the 2026-08-18 source and the 3.14.0 tag:

| SDK rule | Change | Effect on many_lints |
|---|---|---|
| `future_sync_value` | new, `stable` since 3.14, `nonPerformant`, has fix | No counterpart in many_lints. It flags `Future.value(x)` for a plain value and suggests `Future.syncValue`. |
| `unnecessary_this_alias` | new, `experimental` since 3.14 | No counterpart. Only reports with the `this-promotion` experiment enabled (it stayed silent on a plain 3.14.0 run). |
| `migrate_design_widgets` | `experimental` → `stable` (since 3.13, `flutter` category) | No counterpart; listed under Gaps. It drives the Flutter 3.50 `material_ui` / `cupertino_ui` migration. |
| `unnecessary_await_in_return` | `stable` → `deprecated` | Enabling it now reports `deprecated_lint`. It advised the opposite of `prefer_return_await` inside a `try`; that conflict is gone. The rule page no longer links it. |
| `use_primary_constructors` | `experimental` (3.13.0 file) → internal `testing` state, so it is missing from the 3.14.0 file | Still runs when named in `analysis_options.yaml` on 3.14.0 (checked). See Watch. |

No other SDK rule changed state between the two sources. The `sets` field is
empty in every entry of the 3.11.0, 3.13.0 and 3.14.0 files, so set membership
below comes from `package:lints` and `flutter_lints` YAML.

## Summary

| Verdict | Count |
|---|---|
| DUPLICATE | 0 |
| SUPERSET | 1 |
| SUBSET | 10 |
| ADJACENT | 14 |
| WATCH | 3 |
| UNIQUE | 236 |

`prefer_type_over_var` is counted once, under WATCH (the previous report listed
it under both ADJACENT and WATCH). The removed `prefer_contains` and
`avoid_unnecessary_overrides_in_state` names remain registered as tombstones;
`prefer_contains` is the only exact-name match with an SDK rule, and it is
intentional.

## Action deferred until the minimum SDK reaches Dart 3.13

The minimum SDK is still `^3.11.0` in 1.3.0, so nothing here is actionable yet.

### SUPERSET

- [ ] **`prefer_return_await`** → SDK
  **[`async_return_with_no_await`](https://dart.dev/tools/linter-rules/async_return_with_no_await)**
  (`stable`, since Dart 3.13, `hasFix`)
  - Ours: "Missing await on returned Future inside try-catch block."
  - SDK: "Return with no await."
  - The SDK rule reports every `Future` returned without `await` from an
    `async` function, in a `catch` clause and outside any `try`. Inside a
    `try` body it stays silent because the analyzer's own
    `unawaited_return_in_try_block` warning reports there. Checked on 3.14.0:
    a `try` return got only `unawaited_return_in_try_block`, a `catch` return
    and an expression body got `async_return_with_no_await`. Together they
    cover every node ours reports, and more.
  - Do not deprecate while many_lints supports Dart 3.11 and 3.12, where the
    replacement does not exist. The rule page now tells Dart 3.13+ users to
    turn ours off if they enable the SDK lint.

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

- **`prefer_typed_exceptions`** (1.1.0) vs SDK `only_throw_errors` — the SDK
  rule accepts any `Exception` or `Error` subtype, so `throw Exception('...')`
  passes it. Ours also reports that, because a caller cannot catch it
  selectively. The rule page names the SDK rule.
- **`avoid_empty_catch`** (1.1.0) vs SDK `empty_catches` — the SDK rule allows
  `catch (_) {}` and a body holding only a comment; ours reports both unless
  `allow_with_comment` restores the SDK policy. The rule page names the SDK
  rule.

### ADJACENT — no action

`avoid_only_rethrow` (SDK `use_rethrow_when_possible` targets `throw e;`, ours
targets a catch body that is *only* `rethrow;`), `avoid_collection_equality_checks`
(SDK `unrelated_type_equality_checks` is about unrelated *types*; ours is about
collections of the same type having no deep equality),
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
bodies rather than duplicate case values), `parameters_ordering`
(alphabetical ordering within required/optional groups; the SDK separately
owns required-before-optional placement), `avoid_todo_comments` (1.1.0; SDK
`flutter_style_todos` enforces the shape of a TODO, ours asks whether the
marker names a tracked issue) and `prefer_module_barrel_imports` (1.3.0; SDK
`implementation_imports` forbids another package's `lib/src`, ours enforces a
module's own entry point, including inside one package).

### Resolved 2026-08-13 (Dart 3.13)

- `use_declaring_parameters` visits `PrimaryConstructorDeclaration` nodes
  only, so it polishes already-migrated classes while
  `prefer_primary_constructors` suggests migrating. No overlap.
  `unnecessary_type_name_in_constructor` fires on the same legacy classes but
  suggests the weaker `new(this.x)` form; the rule page covers it.
  `prefer_private_named_parameters` remains without a direct SDK counterpart.

## Watch (SDK rule not stable — no action this cycle)

- **`prefer_primary_constructors`** — SDK `use_primary_constructors` reports
  the same constructors, plus every class and enum that declares none (it
  wants `enum E() {`). In the 3.14.0 SDK it is in the internal `testing`
  state and absent from `rules.json`, so it cannot displace ours. Since 1.3.0
  ours covers every convertible class and enum, and the rule page tells users
  not to enable both.
- **`prefer_type_over_var`** — SDK `var_with_no_type_annotation`
  (`experimental`) is the closest thing to a direct replacement. It also
  conflicts with the stable `omit_local_variable_types`. Re-check when it
  stabilises.
- **`avoid_redundant_async`** — SDK `unnecessary_async` (`experimental`) has
  the same core goal. Ours applies stricter return-compatibility checks before
  suggesting removal; re-evaluate both visitors if the SDK rule stabilises.

## Candidates for the owner (no change made in 1.3.0)

Nothing is deprecated or removed in 1.3.0. Decisions to make later:

1. **`prefer_return_await`**: deprecate in favour of `async_return_with_no_await`
   in the release that raises the minimum SDK to 3.13. Raising it would also
   let the package take `analyzer` 14.6+ and `analysis_server_plugin` 0.3.25+.
2. **`prefer_primary_constructors`**: no action while the SDK rule is in
   `testing`. If `use_primary_constructors` becomes `stable` with the
   constructor-less cases still reported, keep ours and document the
   difference; if it stops reporting them, reconsider.

## Gaps — Flutter-category SDK rules we do not cover

Coverage information, not a backlog. All `stable`:

| SDK rule | Description |
|---|---|
| `diagnostic_describe_all_properties` | Reference all public properties in debug methods |
| `no_logic_in_create_state` | Don't put any logic in `createState` |
| `use_full_hex_values_for_flutter_colors` | Prefer 8-digit hex for `Color` |
| `use_key_in_widget_constructors` | Use `key` in widget constructors |
| `avoid_web_libraries_in_flutter` | Avoid web-only libraries outside web plugins |
| `sized_box_shrink_expand` | Use `SizedBox.shrink`/`.expand` |
| `sort_child_properties_last` | Sort `child` last in widget creations |
| `migrate_design_widgets` | Import design widgets from `package:material_ui` / `package:cupertino_ui` (new to `stable` in this cycle) |

Five of these are in `flutter_lints/flutter.yaml`, so most Flutter users
already have them on. Adding our own versions would create exactly the
duplication this report exists to prevent.

## Notes

- `flutter_lints/flutter.yaml` still only enables SDK rules and defines none
  of its own, so it adds no name collisions beyond `rules.json`.
- 236 rules have no SDK counterpart at all — the Riverpod, Bloc, hooks, fpdart,
  widget-replacement, banned-* / architecture, test-hygiene and shorthand
  families are entirely unique to this package.
- The only exact-name match among the 264 active rules and 2 tombstones is the
  intentional `prefer_contains` tombstone.
