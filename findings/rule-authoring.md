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
