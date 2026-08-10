---
name: new-lint
description: Creates a new lint rule with tests and, when safe and useful, a quick fix for the many_lints package. Use when the user wants to add a new lint rule.
---

You are creating a new lint rule for the **many_lints** Dart linter package. The user will provide context describing what the lint should detect, possibly a lint name, and optionally reference links.

## Step 1: Parse the user's input

Extract from the user's request:
- **Lint name** (snake_case) — if not provided, derive one from the description
- **Description** — what the lint should detect/warn about
- **Reference links** — any URLs for documentation or examples

## Step 2: Research

Before writing any code:

1. **📖 ALWAYS START HERE: Read the Lint Rule Cookbooks** (in this directory)
   - [rules-patterns.md](rules-patterns.md) — Rule structure, type checking, AST navigation, visitors, reporting, utilities, analyzer APIs
   - [rules-recipes.md](rules-recipes.md) — Copy-paste ready recipes for common scenarios
   - [config-cookbook.md](config-cookbook.md) — **Read before designing any configuration.** Per-rule `exclude` and options. The analyzer's options system cannot carry per-rule options; several obvious approaches warn or silently do nothing.
   - These are your **primary reference** for all implementation patterns
   - **Check the cookbooks FIRST** before researching elsewhere

2. Read these reference docs to understand the framework:
   - [Writing a plugin](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md)
   - [Writing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md)
   - [Testing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md)
   - [Writing assists](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_assists.md)

3. Read any reference links the user provided.

4. If the cookbook doesn't cover your specific pattern, read 1-2 existing rules in `lib/src/rules/` and their corresponding fixes in `lib/src/fixes/` and tests in `test/` to understand the codebase patterns. Pick rules that are most similar to the new lint being created.

5. Read `lib/src/type_checker.dart` and `lib/src/ast_node_analysis.dart` for reusable utilities.

## Step 3: Ask clarifying questions

Before implementing, use the input mechanism available in the current
environment to clarify:
- What specific AST nodes/patterns should trigger the lint?
- What should the quick fix do exactly? (e.g., replace widget, rename, remove argument)
- Are there edge cases to consider? (e.g., const constructors, nested expressions, generics)
- Does the lint need to check types from a specific package? (determines TypeChecker usage)

Only ask questions that aren't already answered by the user's input.

## Step 4: Create the lint rule

Create `lib/src/rules/<lint_name>.dart` following this exact pattern:

```dart
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

// Add if needed:
// import 'package:many_lints/src/type_checker.dart';
// import 'package:many_lints/src/ast_node_analysis.dart';

/// <doc comment describing what the rule does>
class <RuleClass> extends ManyLintsRule {
  static const LintCode code = LintCode(
    '<lint_name>',
    '<problem message describing what is wrong>',
    correctionMessage: '<suggestion for how to fix>',
  );

  <RuleClass>()
      : super(
          name: '<lint_name>',
          description: '<short description>',
        );

  @override
  LintCode get diagnosticCode => code;

  // Note: `registerManyLintsProcessors`, not `registerNodeProcessors` —
  // `ManyLintsRule` implements the latter to wire up per-rule `exclude`.
  @override
  void registerManyLintsProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    // Register for the appropriate AST node type, e.g.:
    // registry.addInstanceCreationExpression(this, visitor);
    // registry.addClassDeclaration(this, visitor);
    // registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final <RuleClass> rule;

  _Visitor(this.rule);

  // Use TypeChecker for type checks:
  // static const _checker = TypeChecker.fromName('WidgetName', packageName: 'flutter');

  @override
  void visit<NodeType>(<NodeType> node) {
    // Detection logic here
    // Report with: rule.reportAtNode(node) or rule.reportAtToken(node.name)
  }
}
```

Key conventions:
- Rule class name: PascalCase version of lint name (e.g., `use_class_suffix` -> `UseClassSuffix`)
- Use `TypeChecker.fromName()` or `TypeChecker.fromUrl()` for type checks
- Use Dart 3.0+ pattern matching for AST analysis
- Use helpers from `lib/src/ast_node_analysis.dart` when applicable
- `correctionMessage` is required by the docs generator; always provide it

## Step 4b: Add a mode option only when it earns its place

**Per-rule `exclude` is already handled.** Because the rule extends
`ManyLintsRule` and overrides `registerManyLintsProcessors`, users can write

```yaml
# many_lints.yaml
rules:
  <lint_name>:
    exclude: ["**/*.g.dart"]
```

with no code in the rule. Do not add an `exclude` option, and do not add a
`ResolvedRuleConfig` guard to your visitor callbacks — the base class suppresses
diagnostics for excluded files at the reporter.

This step is therefore only about **mode options**. Most rules need none.
Before adding one, check in this order:

1. **Severity already covers it.** Enable/disable and severity overrides work
   natively with zero code — `plugins: many_lints: diagnostics: {<lint_name>: false}`.
   Never build an option for something this handles.
2. **The rule should just be right.** If an "option" encodes a decision the
   heuristic ought to make correctly, fix the heuristic instead.
3. **Only one project would set it.** Not worth the maintenance and testing cost.

Add a mode option only when the rule has a genuine policy where reasonable
teams disagree. "Turn this off in tests" is
not one — that is `exclude`, which you already get for free.

**📖 If you are adding a mode option, read [config-cookbook.md](config-cookbook.md) first.**
It documents hard constraints that are expensive to rediscover — in short:
per-rule options **cannot** live in `analysis_options.yaml` under `plugins:`
(custom keys there emit `unsupported_option`, and map-valued `diagnostics:`
entries are a reported error); a rule cannot reach `AnalysisOptions`; and a
plugin cannot report diagnostics against YAML files at all.

Read the option from `rule.config`, which is already resolved for the file
being visited:

```dart
final someMode = rule.config.boolOption('some_mode', defaultValue: false);
```

Every option's default must reproduce the rule's existing behavior exactly, so
upgrading never changes results silently.

Rules with a mode option need the extra tests in Step 7 and the extra docs
section in Step 9; both are specified in the cookbook.

## Step 5: Create a quick fix when applicable

Create a fix when the user requests one or when the transformation is safe,
deterministic, and preserves behavior. If no safe automatic edit exists, skip
the fix and document the rule without fix badges.

**📖 Consult the Quick Fix Cookbook:** See [fixes-cookbook.md](fixes-cookbook.md) for comprehensive patterns and examples.

Create `lib/src/fixes/<lint_name>_fix.dart` following this exact pattern:

```dart
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that <description of what the fix does>.
class <FixClass> extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.<lintNameCamelCase>',
    DartFixKindPriority.standard,
    '<Short description of the fix action>',
  );

  <FixClass>({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // nodeCovering returns the deepest matching node. Walk up to the semantic
    // target instead of type-testing node or node.parent directly.
    final targetNode = node.thisOrAncestorOfType<RelevantAstNode>();
    if (targetNode == null) return;
    // Apply fix using builder.addDartFileEdit(file, (builder) { ... });
  }
}
```

Key conventions:
- Fix class name: PascalCase rule name + `Fix` suffix (e.g., `PreferCenterOverAlignFix`)
- FixKind ID: `many_lints.fix.<lintNameInCamelCase>`
- Use `range.node()` for replacing nodes, `range.nodeInList()` for removing from argument lists
- Use `addSimpleReplacement()` for simple text replacements
- Use `addDeletion()` for removing code

## Step 6: Register in many_lints.dart

Edit `lib/many_lints.dart`:

1. Add the rule import and, when applicable, the fix import
2. Add `_registerWarningRule(registry, <RuleClass>());` in the rules section.
   This project wrapper is required to keep plugin diagnostics/configuration in sync.
3. If a fix exists, add `registry.registerFixForRule(<RuleClass>.code, <FixClass>.new);` in the fixes section

## Step 6b: Decide the rule's preset

Registering a rule does **not** switch it on — rules are opt-in. Decide which preset in
[`lib/src/presets.dart`](../../../lib/src/presets.dart) the rule belongs to, and add its
name there if any:

- **`coreRules`** — the rule flags a near-certain bug: dead, contradictory or unreachable
  code, a guaranteed runtime misbehaviour, a leaked resource. No stylistic judgement, and
  essentially no false positives.
- **`_recommendedOnlyRules`** — idiomatic, widely-agreed Dart/Flutter practice, or a
  likely-but-not-certain mistake. Must be uncontroversial: something the Dart or Flutter
  team would plausibly endorse.
- **neither** — the rule imposes an architecture, a naming scheme, or a contested style
  choice, has a meaningful false-positive rate, or does nothing until configured (any
  `banned_*`-style rule). Leave it out of both sets; `preset: all` still picks it up.

When torn, pick the lower tier. A preset must stay defensible as "safe and
non-opinionated" — a user enabling `recommended` must not get taste imposed on them.

`presets_test.dart` asserts every preset name is a real registered rule, so a typo or a
later rename fails the suite rather than silently shrinking a preset.

## Step 7: Create tests

Create `test/<lint_name>_test.dart` following this exact pattern:

```dart
import 'package:many_lints/src/rules/<lint_name>.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(<RuleClass>Test));
}

@reflectiveTest
class <RuleClass>Test extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = <RuleClass>();
    // Mock external packages if needed:
    // newPackage('package_name').addFile('lib/file.dart', r'''
    //   class SomeClass {}
    // ''');
    super.setUp();
  }

  // Test cases that SHOULD trigger the lint:
  Future<void> test_<descriptive_case_name>() async {
    await assertDiagnostics(
      r'''
<code that should trigger the lint>
''',
      [lint(<offset>, <length>)],
    );
  }

  // Test cases that should NOT trigger the lint:
  Future<void> test_<descriptive_valid_case>() async {
    await assertNoDiagnostics(r'''
<code that should not trigger the lint>
''');
  }
}
```

Key conventions:
- Test class name: `<RuleClass>Test`
- Use `assertDiagnostics(code, [lint(offset, length)])` for code that triggers the lint
- Use `assertNoDiagnostics(code)` for code that should NOT trigger the lint
- Use `newPackage('name').addFile()` to mock external package dependencies
- Include at least: 2 positive cases (triggers lint), 2 negative cases (no lint), 1 edge case

🚨 Extend `ManyLintsRuleTest` (from `test/many_lints_rule_test_base.dart`), **not**
`AnalysisRuleTest` directly. Rules are opt-in, and a rule test writes no configuration,
so against the stock base class every assertion would run against a rule that is switched
off — `assertDiagnostics` would find nothing and `assertNoDiagnostics` would pass
vacuously. The base class writes `preset: all` into the test package and clears
`ConfigLoader`'s static cache, restoring the state these tests assume.

`ManyLintsRuleTest` covers essentially every rule. The only exception is an
end-to-end test driving a real `PluginServer` (see
`test/plugin_diagnostics_config_test.dart`), where two details matter with
analysis_server_plugin 0.3.18+:

- The protocol request is `AnalysisSetAnalysisRootsParams(included, excluded)` —
  `analysis.setContextRoots` was renamed to `analysis.setAnalysisRoots`.
- Analysis runs asynchronously through the driver scheduler, so `tearDown` must
  `await pluginServer.waitForIdle()` **before** `channel.close()`. Skipping it
  makes background analysis report to a closed channel.

Note that `analyzer_testing` (0.3.4) still exposes no API for testing quick-fix
or assist *output* — only `AnalysisRuleTest` for diagnostics. Fixes are covered
anyway: `PluginServer` answers `edit.getFixes`, and `test/fix_harness.dart`
wraps that so a fix can be checked by the text it actually produces. Every fix
has output tests. New batches belong under `test/fix_output/`; a few older
batches remain in `test/plugin_fix_output_test.dart`. See
[Testing a Fix](fixes-cookbook.md#testing-a-fix). Assist tests drive
`CorrectionProducerContext` directly; see
[assists-cookbook.md](assists-cookbook.md).

If Step 5 created a fix, add its output-test group under `test/fix_output/`
before proceeding.

If Step 4b made the rule configurable, `ManyLintsRuleTest` **cannot** cover it —
its `preset: all` config file is exactly what a config test needs to replace. Add a `PluginServer`-driven group
following `test/rule_config_test.dart`, and remember `ConfigLoader.clearCache()`
in `setUp` (the cache is static and survives across tests).

🚨 Two traps that make config tests pass while proving nothing:

- **Pick a pure-Dart fixture.** Rules needing Flutter types do not resolve under
  `createMockSdk`, so the rule reports nothing and every "excluded" assertion
  passes vacuously. Always include a no-config test asserting the rule *does* fire.
- **Pair every negative test with an asymmetric positive one.** `exclude: [lib/**]`
  on a file in `lib/` must be silent, *and* `exclude: [test/**]` on that same file
  must still report. Silence alone cannot distinguish "exclusion worked" from
  "the rule never fired". Same for modes: assert the option suppresses its target
  case **and** leaves other cases reporting.

See [config-cookbook.md](config-cookbook.md#testing-a-configurable-rule) for the
full coverage checklist.
- `lint(offset, length)` — offset is the character position, length is the length of the reported node/token
- Method names start with `test_` and use camelCase

## Step 8: Update the Cookbooks (MANDATORY when discovering new patterns)

**🚨 CRITICAL: If you discovered or researched any new patterns, you MUST update the cookbooks before completing this task.**

You must update if you:
- ✅ Discovered a new analyzer API pattern (e.g., different way to access elements, types, or AST nodes)
- ✅ Researched AST traversal techniques not shown in the cookbook
- ✅ Found a new type checking method or TypeChecker usage pattern
- ✅ Implemented a complex visitor pattern for deep analysis
- ✅ Created a new helper utility function
- ✅ Had to dig into analyzer source code or documentation for APIs not covered in the cookbook
- ✅ Found analyzer ^14.1.0 specific behaviors different from what you "know" from training data

**How to update (two places):**

1. **Full details** — Add to the appropriate cookbook file in this directory:
   - [rules-patterns.md](rules-patterns.md) for foundational patterns (type checking, AST, visitors, etc.)
   - [rules-recipes.md](rules-recipes.md) for new recipes (specific use-case patterns)
   - [fixes-cookbook.md](fixes-cookbook.md) for fix-related patterns
   - [config-cookbook.md](config-cookbook.md) for configuration patterns, and whenever an analyzer upgrade changes what `AnalysisOptionsFileKeys.pluginsOptions` or `RuleConfig` support
   - Follow the format in each file's Meta-Instructions section

2. **Brief mention** — Add a short entry to the lean quick reference at `lib/src/rules/AGENTS.md` (or `lib/src/fixes/AGENTS.md` for fix patterns)

This keeps the cookbooks as **living documents** that improve with each new rule!

## Step 9: Create a documentation page

Create `docs/src/content/docs/docs/rules/<category>/<lint-name>.md` for the new rule
— or `.mdx` if the rule is configurable (see the Options guidance at the end of this step).

**Determine the category** by matching the lint's domain to one of the existing sidebar categories:
- `class-naming` — Suffix/naming rules for classes (Bloc, Cubit, Notifier, etc.)
- `bloc-riverpod` — Bloc/Riverpod architecture rules
- `riverpod-state` — Riverpod state/ref usage rules
- `async-safety` — Async/await safety rules
- `widget-best-practices` — Widget usage best practices
- `widget-replacement` — Prefer simpler/more specific widgets
- `state-management` — StatefulWidget/setState rules
- `control-flow` — Control flow, cascades, exceptions, switches
- `collection-type` — Collection/Iterable/Map rules
- `pattern-matching` — Dart pattern matching rules
- `type-annotations` — Type annotation preferences
- `code-organization` — Code structure and organization
- `shorthand-patterns` — Shorthand/constructor sugar
- `hook-rules` — Flutter Hooks rules
- `testing-rules` — Test-related rules
- `resource-management` — Disposal, listeners, subscriptions
- `code-quality` — General code quality

If no existing category fits, create a new directory AND add a matching `autogenerate` entry in `docs/astro.config.mjs` sidebar config.

Add `<lint_name>` exactly once to the matching category in
`docs/scripts/generate-rule-pages.mjs`, even when the category already exists.

**Use this template** (match the format of existing pages):

```markdown
---
title: <lint_name>
description: "<Short description>"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: <lint_name>
---

<span class="rule-badge rule-badge--version">vX.Y.Z</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category"><Category Name></span>

<2-3 sentence human-friendly description of what the lint detects and why it matters.>

## Why use this rule

<Real-world context explaining why this pattern is problematic. Include "See also" links to relevant official docs.>

**See also:** <replace with descriptive links to authoritative references>

## Don't

```dart
// Bad example with comment explaining why it's wrong
<code that triggers the lint>
```

## Do

```dart
// Good example
<correct code>
```

## Turning this rule off

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      <lint_name>: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
```

If Step 4b made the rule configurable, the page needs three more things:

1. Name the file `.mdx`, not `.md`, and import the tabs component directly
   below the frontmatter:
   `import { Tabs, TabItem } from '@astrojs/starlight/components';`
2. Add a `<span class="rule-badge rule-badge--config">Configurable</span>` badge
   immediately before the category badge.
3. Add an `## Options` section — a **sibling** of "Turning this rule off", not a
   subsection of it — holding the YAML example in a `<Tabs syncKey="many-lints-config-file">`
   group showing both `analysis_options.yaml` and `many_lints.yaml`, followed by a
   table of option / type / **default** / description. Always state defaults.

Never show an options snippet in only one of the two files, and keep the
`# analysis_options.yaml` / `# many_lints.yaml` comment as the first line of each
snippet — that comment is what tells the reader where the YAML goes.

See [config-cookbook.md](config-cookbook.md#documenting-a-configurable-rule) for
the exact template.

Key notes:
- Omit the `sidebar.badge` block entirely if the lint has **no quick fix**
- Omit the `<span class="rule-badge rule-badge--fix">Fix</span>` badge if there is no fix
- Determine the version tag: check the latest version in `pubspec.yaml` — if this is a new unreleased rule, use the next version that will be released
- Use the lint name with underscores (snake_case) for `title` and `label`
- Use dashes (kebab-case) for the filename (e.g., `prefer-center-over-align.md`)

## Step 10: Create an example file

Create `example/lib/<lint_name>_example.dart` to demonstrate the lint rule. Look at existing example files in `example/lib/` for the pattern.

The example file should include:
- A file-level `// ignore_for_file: unused_local_variable` (or similar) to suppress unrelated warnings
- Prefixed ignores such as `// ignore_for_file: many_lints/<other_rule>` for
  unrelated plugin diagnostics; never suppress the rule demonstrated by the file
- A comment header with the lint name and brief description
- **Bad examples** (code that triggers the lint) with `// LINT:` comments explaining each case
- **Good examples** (correct code that does NOT trigger the lint)
- **Edge cases** where the lint intentionally does NOT trigger (e.g., when `.from()` is needed for downcasting)

Example structure:
```dart
// ignore_for_file: unused_local_variable

// <lint_name>
//
// Brief description of what the lint detects.

// ❌ Bad: Description of bad pattern
class BadExamples {
  void example() {
    // LINT: Explanation of why this triggers
    final x = badCode();
  }
}

// ✅ Good: Description of correct pattern
class GoodExamples {
  void example() {
    final x = goodCode();
  }
}
```

## Step 11: Verify

Run the following commands from the project root to ensure everything works:

1. Synchronize the registered-rule total and indexes in `README.md`,
   `example/README.md`, `docs/src/content/docs/docs/configuration.md`, and
   `docs/src/content/docs/docs/getting-started.mdx`. Verify exact set equality
   among registered rules, rule sources, examples, docs pages, the example README
   table, and the generator category map.
2. `dart format --output=none --set-exit-if-changed .` - Ensure all Dart files are formatted.
3. `dart analyze` - Ensure there are **no issues at all** (errors, warnings, or infos). Fix any that appear before proceeding.
4. `dart test` - Ensure all tests pass
5. Analyze `example/` in machine format and verify that the new example emits
   its target rule and no unrelated `many_lints` or SDK diagnostics.
6. Run `bun run build` from `docs/` as the final gate.

If any check fails or reports issues, fix it and re-run the affected checks until all are fully clean.
