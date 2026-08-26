# Configurable Rule Authoring

Lessons from making rules accept options (v0.9.0+).

### [GOTCHA] [CRITICAL] A `LintCode` built in the constructor goes stale when an option feeds its message
**Area:** `lib/src/class_affix_validator.dart`
**Tags:** `#gotcha` `#architecture`
**Verified:** 2026-08-08

**Symptom:** After making the suffix rules accept a `suffix` option, a rule correctly enforced `Store` but the diagnostic still read `Use Bloc suffix`. Tests asserting only on the diagnostic **code** passed, hiding it completely.

**Root cause:** The base class stored its `LintCode` in a `final` field built in the constructor. Constructor-time state cannot reflect per-file configuration, which is resolved much later.

**Workaround:** Make `diagnosticCode` a **getter** that rebuilds the `LintCode` on each access — every `reportAt*` method reads the getter at report time rather than capturing it once.

**But only when the text is constant per file.** Once one file can produce several different values (one per matched config entry), a per-access `LintCode` mints a *different* code object per report, and `registerFixForRule` keys the fix registry on the `LintCode` — so the quick fix silently stops being offered. In that case keep one `static const` code with `{0}` placeholders and pass the varying part via `arguments:`.

**Rule of thumb:** option affects the message **per file** → getter; **per diagnostic** → `static const` code plus `arguments:`. Either way the test must assert on the **message**, not just the code.

---

### [GOTCHA] [CRITICAL] `TypeChecker.isSuperOf` is reflexive, so a configured base type matches itself
**Area:** `lib/src/class_affix_validator.dart`
**Tags:** `#gotcha` `#architecture`
**Verified:** 2026-08-08

**Symptom:** With `use_class_prefix` configured as `{type: Repository, prefix: Db}`, the abstract `Repository` declaration itself was reported for not being named `DbRepository`.

**Root cause:** `TypeChecker.isSuperOf` calls `isExactly(element)` before walking `allSupertypes`, so the base type satisfies its own checker.

**Why it only surfaced now:** the three predecessor rules hardcoded base types owned by dependencies (`Bloc`, `Cubit`, `Notifier`), which are never declared in the analyzed package. A *user-configured* type usually is — and for a dependency's type the user could not act on the diagnostic anyway.

**Workaround:** `if (checker.isExactly(element)) continue;` before the `isSuperOf` test. Caught only by running the real example project, not by any unit test.

---

### [NOTE] [GOTCHA] A quick fix can read per-rule config, but its `FixKind` cannot depend on it
**Area:** `lib/src/fixes/add_affix_fix.dart`
**Tags:** `#architecture` `#tooling`
**Verified:** 2026-08-08

A `ResolvedCorrectionProducer` has no `RuleContext`, but it can resolve the same configuration the rule used:

```dart
ResolvedRuleConfig.forPath(
  packageRoot: unitResult.session.analysisContext.contextRoot.root,
  path: unitResult.path,
  ruleName: 'use_class_suffix',
);
```

**The constraint:** `registerFixForRule` instantiates the producer at *registration* time with `StubCorrectionProducerContext.instance` and throws if `fixKind` is null (`analysis_server_plugin/src/registry.dart:52`). So `fixKind` must be a constant — one per rule. Anything config-derived has to live inside `compute`.

Factor the matching logic into a helper taking a `RuleConfig` (not a rule) so rule and fix cannot drift apart. Prefer re-deriving from config over parsing the diagnostic message, which is the pattern `dispose_fields_fix.dart` already uses.

Testing needs `FixHarness.applyFix(..., manyLintsConfig: ...)`, and the harness must call `ConfigLoader.clearCache()` in `setUp` — the cache is static and keyed by package root, which every harness instance reuses.

---

### [GOTCHA] [CRITICAL] Configuring detection without recognition turns an option into a false positive
**Area:** `lib/src/disposal_utils.dart`
**Tags:** `#gotcha` `#data-integrity`
**Verified:** 2026-08-08

**Symptom:** `dispose_fields` uses its cleanup-method list **twice** — once to decide a field *needs* cleanup, and again in a separate `_CleanupCallCollector` to recognise a call that *performs* it. Threading a configured list into only the first makes a project's `release()` report as "never disposed" even where it is disposed.

**Root cause:** The two uses live in different classes, so it is easy to update one and miss the other. `dispose_provided_instances` has the same shape across *three* collectors (`_DisposableVariableFinder`, `_OnDisposeCollector`, `_CleanupCallFinder`).

**Workaround:** Resolve the list **once per callback** and pass it into every collector that consumes it. Before adding any list-valued option, grep for every use of the constant being replaced.

Related: the list is a `List`, not a `Set`, because order is the priority used when a type declares several cleanup methods.

---

### [NOTE] [GOTCHA] Nested YAML structure survives config parsing — only accessors are missing
**Area:** `lib/src/rule_config.dart`
**Tags:** `#architecture` `#tooling`
**Verified:** 2026-08-08

`RuleConfig._fromYaml` stores `options[name] = value.value`, which **preserves nested `YamlMap`/`YamlList` structure**. Verified empirically with a probe run inside the package:

```
runtimeType of .value => YamlList
first elem type       => YamlMap
deny                  => [package:http/.*] (YamlList)
```

**Why this matters:** a list-of-maps option — the shape the `avoid_banned_*` family needs (`{deny: [...], in: [...], message: ...}`) — requires only a **new typed accessor** on `RuleConfig`, not a parser rewrite. The blocker for that whole rule family is far smaller than it appears.

Note the probe must run inside the package (`dart test/probe.dart`), not from `/tmp`, or `package:yaml` will not resolve.

---

### [NOTE] [NOTE] A shared rule base class makes a whole family configurable in one edit
**Area:** `lib/src/class_affix_validator.dart`
**Tags:** `#architecture` `#design-decision`
**Verified:** 2026-08-08

Three suffix rules shared one base class that took the suffix as a constructor parameter, so reading the option **in the base class** made all three configurable in one edit — the best effort-to-value ratio in the config work.

**But the follow-up mattered more.** The base type was *also* a constructor argument, so the package still enforced naming for exactly three hardcoded types and a project wanting `...Repository` had to fork. Replacing the three with `use_class_suffix` / `use_class_prefix`, which read an `entries:` list, removed the ceiling entirely.

**Generalisation:** when a constructor argument encodes *which thing the rule looks for*, that is usually configuration, not a subclass. Three near-identical subclasses is the smell. Also check the inverse — `prefer_shorthands_with_constructors` hardcoded its class list at *two* call sites in one file, and both had to be updated.

**Guard against degenerate values:** an empty `suffix: ""` would make every name "end with" it, silently disabling the rule. Treat empty as absent, and test it.

---

### [GOTCHA] [CRITICAL] "The rule already does that" argues *for* an option, not against it
**Area:** `lib/src/rules/` (Tier 3 option pass)
**Tags:** `#gotcha` `#design-decision`
**Verified:** 2026-08-09

**Symptom:** eight proposed per-rule options were rejected with the reasoning *"the rule already behaves that way, so the flag would control nothing."* All eight were later reinstated as working, tested options.

**Root cause:** that reasoning silently assumes an option **narrows**. When the rule's current behaviour *is* the narrow one, the option **widens** — and the default still reproduces today's results exactly, which is all the "defaults preserve behaviour" rule actually demands.

| Rule's current behaviour | Wrong conclusion | Actual option |
|---|---|---|
| Enums exempt from `avoid_default_tostring` | "`ignore_enums` is dead code" | `report_enums: true` widens to them |
| Parameter must match the field name | "`only_same_name: true` is permanent" | `only_same_name: false` widens to renamed parameters |
| Fallthrough cases never reported | "the quick fix can't act on them" | Teach the fix `case a \|\| b`, then `allow_fallthrough_cases` |
| Keys on Bloc's `on` / `emit` | "a project can't rename Bloc's API" | It can *wrap* it — `additional_methods` |

**The misread guidance:** the cookbook's "prefer options that make a rule quieter" is about which behaviour ships as the **default**, so upgrades never surprise anyone. It does not mean an option may only subtract. `state_base_classes`, `report_enums` and `additional_methods` all add reports and are all correct.

**Test before concluding a flag is inert:** ask *"what would `true` do?"*. Reject only when there is genuinely no dimension to act on — `dispose_fields.ignore_blocs` fails because the rule never reaches a Bloc at all, and the fix there is the widening `state_base_classes`, not the narrowing flag.

**If widening needs the quick fix to handle a new shape, extend the fix.** `allow_fallthrough_cases` was worth the extra work in `prefer_switch_expression_fix.dart` (accumulate empty cases, join with `||`, collapse to `_` when the body is `default`'s). When a fix genuinely must *not* act — `only_same_name: false` would rename a named argument and break call sites — let the rule report and have the fix decline, with a comment saying why.

**Record rejections in the rule's source, naming the missing dimension.** A bare "not configurable" invites the next pass to re-add it; a stated reason survives.

---

### [GOTCHA] [GOTCHA] An option that gates nothing still compiles and still tests green
**Area:** `lib/src/rules/avoid_default_tostring.dart`, `avoid_misused_hooks.dart`
**Tags:** `#gotcha` `#testing`
**Verified:** 2026-08-09

The mirror image of the finding above: a plausible option list — a rule catalogue, a planning document, earlier notes — is a *hypothesis* about the rule, not a fact about it.

`avoid_default_tostring` gates on `element is! ClassElement`, which already excluded enums, so an `ignore_enums` flag would have been dead code — with a passing test asserting enums are exempt, which they were regardless of the option. `avoid_misused_hooks` reports hooks inside loops and never resolves an enclosing widget, so a proposed `ignored_widgets` had nothing to match until the widget lookup was actually added.

**Rule:** every option needs a fixture where the rule's output differs with and without it. If you cannot construct one, the option is not real. This is the vacuous-test trap one level up — there, a rule that never fires makes assertions meaningless; here, an option that gates nothing does, even though the rule fires correctly.

**Corollary for planning documents:** a proposed-options table is worth exactly as much as the reading behind it. Read the visitor before wiring, and note in the doc which rows were checked against source.

---

### [GOTCHA] [CRITICAL] `Metadata.hasImmutable` resolves through `package:meta` — a fake annotation is invisible to it
**Area:** `lib/src/immutable_state_rule.dart`, any rule reading `element.metadata.has*`
**Tags:** `#gotcha` `#testing`
**Verified:** 2026-08-26 (analyzer 14.1.0)

**Symptom:** a rule change that skips classes already carrying `@immutable` appears to do nothing. `element.metadata.hasImmutable` returns `false` for a test fixture that visibly has the annotation.

**Cause:** the analyzer's `has*` getters are **semantic**, not syntactic. `isImmutable` is

```dart
_isPackageMetaGetter(_immutableVariableName) || _isPackageMetaConstructor(_immutableClassName)
```

and `_isPackageMetaGetter` requires a top-level getter named `immutable` **in a library whose `name` is `meta`** (or a class named `Immutable`, capital I). This package's test fixtures had declared a stand-in:

```dart
// Invisible to hasImmutable: lowercase class, no library name.
class immutable { const immutable(); }
const immutable = immutable();
```

which satisfies a *syntactic* check (`annotation.name.name == 'immutable'`, which the rule's own `_hasImmutableAnnotation` uses) while being unrecognisable to the semantic one. The two checks silently disagreed.

**Fix:** make the fake faithful to the real package.

```dart
newPackage('meta').addFile('lib/meta.dart', r'''
library meta;

class Immutable {
  const Immutable([this.reason]);
  final String? reason;
}
const Immutable immutable = Immutable();
''');
```

**General lesson:** before using any `metadata.hasX` getter, check how the analyzer resolves it (`analyzer/lib/src/dart/element/element.dart`). Most pin `package:meta` by **library name**, so a minimal fixture that "looks right" fails. If a rule mixes a syntactic annotation check with a semantic one, expect them to disagree on fixtures until the fake carries a `library` directive and the real class name.

---

### [NOTE] [GOTCHA] `ExtensionElement` is not an `InterfaceElement`
**Area:** `lib/src/rules/banned_usage.dart`, any rule walking `element.enclosingElement`
**Tags:** `#gotcha`
**Verified:** 2026-08-26 (analyzer 14.1.0)

A member declared on an `extension` has an enclosing element that is an `InstanceElement` but **not** an `InterfaceElement`. Code shaped like

```dart
final enclosing = element.enclosingElement;
if (enclosing is! InterfaceElement) return const [];
```

therefore declines for extension members exactly as it does for top-level functions — silently, and for a reason that is easy to misread as "top-level functions are unmatchable".

The user-visible consequence in `banned_usage`: with `deny: ['unawaited']` configured, both `unawaited(f())` **and** a project's own `f.unawaited()` extension member are reported, because only the bare-name lookup can reach either and by bare name they are indistinguishable. Reaching `ExtensionElement.extendedType` would allow `Future.unawaited` to be denied precisely; a library-qualified deny form (`dart:async/unawaited`) would separate the SDK function from a same-named local declaration. Neither is implemented — see `TODO/banned-usage-misses-top-level-functions.md`.

