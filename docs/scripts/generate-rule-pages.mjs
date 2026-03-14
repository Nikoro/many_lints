#!/usr/bin/env node

/**
 * Generates documentation pages for each lint rule from source code.
 *
 * Data sources:
 * - lib/src/rules/*.dart         → rule name, problem message, correction message
 * - lib/many_lints.dart          → which rules have quick fixes
 * - example/lib/*_example.dart   → code examples
 *
 * Usage:
 *   node docs/scripts/generate-rule-pages.mjs           # skip existing files
 *   node docs/scripts/generate-rule-pages.mjs --force    # overwrite all files
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync } from 'fs';
import { join, basename } from 'path';

const ROOT = join(import.meta.dirname, '..', '..');
const RULES_DIR = join(ROOT, 'lib', 'src', 'rules');
const EXAMPLES_DIR = join(ROOT, 'example', 'lib');
const PLUGIN_FILE = join(ROOT, 'lib', 'many_lints.dart');
const OUTPUT_DIR = join(ROOT, 'docs', 'src', 'content', 'docs', 'docs', 'rules');
const FORCE = process.argv.includes('--force');

// ── Category mapping ──────────────────────────────────────────────────────────

const CATEGORIES = {
  'class-naming': {
    label: 'Class Naming',
    rules: ['use_bloc_suffix', 'use_cubit_suffix', 'use_notifier_suffix'],
  },
  'bloc-riverpod': {
    label: 'Bloc / Riverpod',
    rules: [
      'avoid_bloc_public_methods',
      'avoid_passing_bloc_to_bloc',
      'avoid_passing_build_context_to_blocs',
      'prefer_bloc_extensions',
      'prefer_immutable_bloc_state',
      'prefer_multi_bloc_provider',
      'avoid_notifier_constructors',
      'avoid_public_notifier_properties',
      'dispose_provided_instances',
    ],
  },
  'riverpod-state': {
    label: 'Riverpod State',
    rules: ['avoid_ref_inside_state_dispose', 'avoid_ref_read_inside_build'],
  },
  'async-safety': {
    label: 'Async Safety',
    rules: ['use_ref_and_state_synchronously', 'use_ref_read_synchronously'],
  },
  'widget-best-practices': {
    label: 'Widget Best Practices',
    rules: [
      'avoid_flexible_outside_flex',
      'avoid_returning_widgets',
      'avoid_shrink_wrap_in_lists',
      'avoid_single_child_in_multi_child_widgets',
      'avoid_unnecessary_consumer_widgets',
      'avoid_unnecessary_gesture_detector',
      'avoid_unnecessary_hook_widgets',
      'avoid_conditional_hooks',
      'prefer_single_widget_per_file',
      'use_closest_build_context',
      'use_gap',
      'use_sliver_prefix',
      'prefer_spacing',
      'use_dedicated_media_query_methods',
    ],
  },
  'widget-replacement': {
    label: 'Widget Replacement',
    rules: [
      'prefer_center_over_align',
      'prefer_align_over_container',
      'prefer_constrained_box_over_container',
      'prefer_padding_over_container',
      'prefer_transform_over_container',
      'avoid_border_all',
      'avoid_expanded_as_spacer',
      'avoid_incorrect_image_opacity',
      'avoid_wrapping_in_padding',
      'prefer_container',
      'prefer_sized_box_square',
      'prefer_text_rich',
      'prefer_const_border_radius',
    ],
  },
  'state-management': {
    label: 'State Management',
    rules: [
      'avoid_state_constructors',
      'avoid_unnecessary_stateful_widgets',
      'avoid_unnecessary_overrides',
      'avoid_unnecessary_overrides_in_state',
      'avoid_unnecessary_setstate',
      'avoid_mounted_in_setstate',
    ],
  },
  'control-flow': {
    label: 'Control Flow',
    rules: [
      'avoid_cascade_after_if_null',
      'avoid_constant_conditions',
      'avoid_constant_switches',
      'avoid_contradictory_expressions',
      'avoid_duplicate_cascades',
      'avoid_only_rethrow',
      'avoid_throw_in_catch_block',
      'prefer_switch_expression',
      'proper_super_calls',
      'prefer_return_await',
      'prefer_simpler_patterns_null_check',
    ],
  },
  'collection-type': {
    label: 'Collection & Type',
    rules: [
      'avoid_accessing_collections_by_constant_index',
      'avoid_collection_equality_checks',
      'avoid_collection_methods_with_unrelated_types',
      'avoid_map_keys_contains',
      'avoid_incomplete_copy_with',
      'list_all_equatable_fields',
      'prefer_any_or_every',
      'prefer_contains',
      'prefer_enums_by_name',
      'prefer_iterable_of',
      'prefer_correct_edge_insets_constructor',
      'prefer_class_destructuring',
      'prefer_overriding_parent_equality',
    ],
  },
  'pattern-matching': {
    label: 'Pattern Matching',
    rules: [
      'avoid_single_field_destructuring',
      'use_existing_destructuring',
      'use_existing_variable',
      'prefer_wildcard_pattern',
    ],
  },
  'type-annotations': {
    label: 'Type Annotations',
    rules: [
      'prefer_type_over_var',
      'prefer_explicit_function_type',
      'prefer_void_callback',
      'prefer_async_callback',
      'prefer_equatable_mixin',
    ],
  },
  'code-organization': {
    label: 'Code Organization',
    rules: [
      'prefer_abstract_final_static_class',
      'avoid_generics_shadowing',
      'prefer_for_loop_in_children',
    ],
  },
  'shorthand-patterns': {
    label: 'Shorthand Patterns',
    rules: [
      'prefer_returning_shorthands',
      'prefer_shorthands_with_constructors',
      'prefer_shorthands_with_enums',
      'prefer_shorthands_with_static_fields',
    ],
  },
  'hook-rules': {
    label: 'Hook Rules',
    rules: ['prefer_use_callback', 'prefer_use_prefix'],
  },
  'testing-rules': {
    label: 'Testing Rules',
    rules: [
      'avoid_misused_test_matchers',
      'prefer_test_matchers',
      'prefer_expect_later',
      'prefer_compute_over_isolate_run',
    ],
  },
  'resource-management': {
    label: 'Resource Management',
    rules: [
      'always_remove_listener',
      'avoid_unassigned_stream_subscriptions',
      'dispose_fields',
    ],
  },
  'code-quality': {
    label: 'Code Quality',
    rules: [
      'avoid_commented_out_code',
      'prefer_single_setstate',
    ],
  },
};

// Build reverse lookup: rule_name → { categorySlug, categoryLabel }
const ruleCategoryMap = {};
for (const [slug, cat] of Object.entries(CATEGORIES)) {
  for (const rule of cat.rules) {
    ruleCategoryMap[rule] = { slug, label: cat.label };
  }
}

// ── Parse rule source files ───────────────────────────────────────────────────

function parseRuleFile(filePath) {
  const content = readFileSync(filePath, 'utf-8');

  // Match the LintCode block — extract everything between LintCode( and the closing );
  const lintCodeBlock = content.match(/LintCode\(([\s\S]*?)\);/);
  if (!lintCodeBlock) return null;

  const block = lintCodeBlock[1];

  // Extract all quoted strings (both single and double quotes) with their positions
  // to parse positional and named arguments
  const stringPattern = /(['"])((?:(?!\1).)*)\1/g;
  const allStrings = [];
  let m;
  while ((m = stringPattern.exec(block)) !== null) {
    allStrings.push({ value: m[2], index: m.index, end: m.index + m[0].length });
  }

  if (allStrings.length < 2) return null;

  // First string is the rule name
  const name = allStrings[0].value;

  // Find where correctionMessage: starts
  const correctionIdx = block.indexOf('correctionMessage:');
  if (correctionIdx === -1) return null;

  // Problem message = all adjacent strings between name and correctionMessage:
  const problemParts = [];
  const correctionParts = [];

  for (let i = 1; i < allStrings.length; i++) {
    if (allStrings[i].index < correctionIdx) {
      problemParts.push(allStrings[i].value);
    } else {
      correctionParts.push(allStrings[i].value);
    }
  }

  if (problemParts.length === 0 || correctionParts.length === 0) return null;

  return {
    name,
    problemMessage: problemParts.join(''),
    correctionMessage: correctionParts.join(''),
  };
}

// ── Parse fix registrations ───────────────────────────────────────────────────

function parseFixRegistrations() {
  const content = readFileSync(PLUGIN_FILE, 'utf-8');
  const fixRules = new Set();

  // Match: registerFixForRule(ClassName.code, ...)
  const matches = content.matchAll(/registerFixForRule\(\s*(\w+)\.code/g);
  for (const match of matches) {
    // Convert PascalCase class name to snake_case rule name
    const className = match[1];
    const snakeName = className
      .replace(/([A-Z])/g, '_$1')
      .toLowerCase()
      .replace(/^_/, '');
    fixRules.add(snakeName);
  }

  return fixRules;
}

// ── Read example files ────────────────────────────────────────────────────────

function readExampleFile(ruleName) {
  const examplePath = join(EXAMPLES_DIR, `${ruleName}_example.dart`);
  if (!existsSync(examplePath)) return null;
  return readFileSync(examplePath, 'utf-8').trim();
}

// ── Generate markdown page ────────────────────────────────────────────────────

function generatePage(rule, categoryLabel, hasFix, example) {
  const badgePart = hasFix
    ? `\n  badge:\n    text: "Fix"\n    variant: "tip"`
    : '';

  let exampleSection = '';
  if (example) {
    exampleSection = `
## Example

\`\`\`dart
${example}
\`\`\`
`;
  }

  return `---
title: ${rule.name}
description: "${rule.problemMessage.replace(/"/g, '\\"')}"
sidebar:${badgePart}
  label: ${rule.name}
---

| Property | Value |
|----------|-------|
| **Rule name** | \`${rule.name}\` |
| **Category** | ${categoryLabel} |
| **Severity** | Warning |
| **Has quick fix** | ${hasFix ? 'Yes' : 'No'} |

## Problem

${rule.problemMessage}

## Suggestion

${rule.correctionMessage}
${exampleSection}
## Configuration

To disable this rule:

\`\`\`yaml
plugins:
  many_lints:
    diagnostics:
      ${rule.name}: false
\`\`\`
`;
}

// ── Main ──────────────────────────────────────────────────────────────────────

function main() {
  console.log('Generating rule documentation pages...\n');

  const fixRules = parseFixRegistrations();
  const ruleFiles = readdirSync(RULES_DIR).filter((f) => f.endsWith('.dart'));

  let generated = 0;
  let skipped = 0;
  let errors = 0;
  const uncategorized = [];

  for (const file of ruleFiles) {
    const rule = parseRuleFile(join(RULES_DIR, file));
    if (!rule) {
      console.warn(`  WARN: Could not parse LintCode from ${file}`);
      errors++;
      continue;
    }

    const category = ruleCategoryMap[rule.name];
    if (!category) {
      uncategorized.push(rule.name);
      continue;
    }

    const outDir = join(OUTPUT_DIR, category.slug);
    const outFile = join(outDir, `${rule.name.replace(/_/g, '-')}.md`);

    if (!FORCE && existsSync(outFile)) {
      skipped++;
      continue;
    }

    mkdirSync(outDir, { recursive: true });

    const hasFix = fixRules.has(rule.name);
    const example = readExampleFile(rule.name);
    const content = generatePage(rule, category.label, hasFix, example);

    writeFileSync(outFile, content);
    generated++;
  }

  console.log(`  Generated: ${generated}`);
  console.log(`  Skipped (existing): ${skipped}`);
  if (errors) console.log(`  Errors: ${errors}`);
  if (uncategorized.length) {
    console.warn(`\n  Uncategorized rules: ${uncategorized.join(', ')}`);
  }
  console.log('\nDone!');
}

main();
