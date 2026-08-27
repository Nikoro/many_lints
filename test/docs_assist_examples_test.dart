import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'fix_harness.dart';
import 'fpdart_stub.dart';

/// Runs every documented assist example through a real `PluginServer` and
/// compares the result to the "After" snippet the documentation claims.
///
/// The examples on `docs/.../assists.md` are the only place a reader learns
/// what an assist produces, and nothing else checks them: `verify_documentation`
/// proves a snippet *parses*, not that it is what the assist actually emits.
/// Without this test an assist can change its output — spacing, indentation, a
/// dropped parameter — and the page keeps advertising the old result
/// indefinitely.
///
/// The fixtures live in `docs/verified/assist_examples.json` rather than inline
/// here so the documented before/after pair stays readable as a pair. When this
/// test fails, the assist changed: update the page section it names, then the
/// fixture.
void main() {
  late FixHarness harness;

  setUp(() async {
    harness = FixHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  final file = File('docs/verified/assist_examples.json');
  if (!file.existsSync()) {
    test('documented assist examples fixture exists', () {
      fail('Missing ${file.path}. Run this test from the package root.');
    });
    return;
  }

  final examples = (jsonDecode(file.readAsStringSync()) as List)
      .cast<Map<String, Object?>>();

  test('every documented example is covered by a fixture', () {
    // A guard against the fixture silently emptying out: the page has one
    // documented conversion per assist plus the multi-shape sections, and a
    // fixture file that lost entries would make this suite vacuously green.
    expect(examples, hasLength(greaterThanOrEqualTo(20)));
  });

  for (final example in examples) {
    final section = example['section']! as String;
    final assistId = example['assist']! as String;
    final usesFpdart = example['fpdart']! as bool;

    test('docs example: $section', () async {
      final result = await harness.applyAssist(
        example['before']! as String,
        assistId,
        multiFilePackages: usesFpdart ? {'fpdart': fpdartStubFiles} : const {},
      );

      expect(
        result.source,
        example['after']! as String,
        reason:
            'The "$section" example in docs/src/content/docs/docs/assists.md '
            'no longer matches what $assistId produces. Update that page '
            'section, then docs/verified/assist_examples.json.',
      );
    });
  }
}
