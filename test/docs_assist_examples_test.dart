import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'fix_harness.dart';
import 'fpdart_stub.dart';

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

  test('the fixture has not silently lost documented examples', () {
    const documentedExamplesAtLeast = 20;
    expect(
      examples,
      hasLength(greaterThanOrEqualTo(documentedExamplesAtLeast)),
    );
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
