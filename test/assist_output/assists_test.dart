import 'package:test/test.dart';

import '../fix_harness.dart';
import '../fpdart_stub.dart';

void main() {
  late FixHarness harness;

  setUp(() async {
    harness = FixHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  group('convert_flat_map_to_do_notation', () {
    Future<({String source, List<dynamic> linkedGroups})> applyAssist(
      String content,
    ) async {
      final result = await harness.applyAssist(
        content,
        'many_lints.assist.convertFlatMapToDoNotation',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );
      return (source: result.source, linkedGroups: result.linkedGroups);
    }

    test('flattens a nest into a Do block', () async {
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');
Option<String> c() => Option.of('c');

Option<String> f() => a().flat^Map(
      (first) => b().flatMap(
            (second) => c().flatMap(
                  (third) => Option.of('$first$second$third'),
                ),
          ),
    );
''');

      expect(result.source, contains(r'Option.Do(($) {'));
      expect(result.source, contains(r"final first = $(a());"));
      expect(result.source, contains(r"final second = $(b());"));
      expect(result.source, contains(r"final third = $(c());"));
      // The innermost `Option.of(x)` unwraps to a plain return, since `Do`
      // wraps the block's result itself.
      expect(result.source, contains(r"return '$first$second$third';"));
      expect(result.source, isNot(contains('flatMap')));
    });

    test('offers every generated name as a linked edit position', () async {
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');

Option<String> f() => a().flat^Map(
      (first) => b().flatMap((second) => Option.of('$first$second')),
    );
''');

      // One group per extracted step, so Tab walks the names.
      expect(result.linkedGroups, hasLength(2));
    });

    test('keeps a non-lifting last step as an extraction', () async {
      // The innermost callback returns a pipeline rather than `Option.of(x)`,
      // so it stays a `$(...)` extraction instead of being unwrapped.
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');
Option<String> c() => Option.of('c');

Option<String> f() => a().flat^Map(
      (first) => b().flatMap((second) => c()),
    );
''');

      expect(result.source, contains(r'return $(c());'));
    });

    test('works on TaskEither too', () async {
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> a() => TaskEither.of(1);
TaskEither<String, int> b() => TaskEither.of(2);

TaskEither<String, int> f() => a().flat^Map(
      (first) => b().flatMap((second) => TaskEither.of(first + second)),
    );
''');

      expect(result.source, contains(r'TaskEither.Do(($) {'));
      expect(result.source, contains(r'return first + second;'));
    });

    test('handles the README shopping example end to end', () async {
      // The chain has work on both sides of the nest: `.alt(...)` folded into
      // the first step's source, and `.getOrElse(...)` left untouched after
      // the block.
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Market {
  Option<String> buyBanana() => Option.of('banana');
  Option<String> buyApple() => Option.of('apple');
}

Option<Market> goToShoppingCenter() => Option.of(Market());
Option<Market> goToLocalMarket() => Option.of(Market());

String goShopping() => goToShoppingCenter()
    .alt(goToLocalMarket)
    .flat^Map(
      (market) => market.buyBanana().flatMap(
            (banana) => market.buyApple().flatMap(
                  (apple) => Option.of('Shopping: $banana, $apple'),
                ),
          ),
    )
    .getOrElse(() => 'nothing bought');
''');

      expect(
        result.source,
        contains(
          r"final market = $(goToShoppingCenter().alt(goToLocalMarket));",
        ),
      );
      expect(result.source, contains(r"final banana = $(market.buyBanana());"));
      expect(result.source, contains(r"final apple = $(market.buyApple());"));
      expect(result.source, contains(r"return 'Shopping: $banana, $apple';"));
      // The tail of the chain survives the rewrite.
      expect(result.source, contains(".getOrElse(() => 'nothing bought')"));
      // Generated lines are indented from the line's own leading whitespace,
      // not from everything preceding the call on that line.
      expect(result.source, isNot(contains('String goShopping() =>   final')));
    });

    test('is offered from anywhere in the nest', () async {
      // The cursor sits on the *inner* flatMap, but the assist rewrites the
      // whole nest from its outermost call.
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');

Option<String> f() => a().flatMap(
      (first) => b().flat^Map((second) => Option.of('$first$second')),
    );
''');

      expect(result.source, contains(r'Option.Do(($) {'));
      expect(result.source, contains(r"final first = $(a());"));
    });
  });

  group('convert_iterable_map_to_collection_for', () {
    // The assist's own transformation logic is covered thoroughly in
    // `test/convert_iterable_map_to_collection_for_test.dart`, which drives
    // `CorrectionProducerContext` directly. That route constructs the assist
    // itself, so it passes whether or not the assist is registered with the
    // plugin — a missing `registerAssist` would be invisible to all ten of
    // those tests.
    //
    // This group closes that gap: one end-to-end pass through a real
    // `PluginServer`, proving the assist is actually offered to an editor.
    test('is offered through the plugin server', () async {
      final result = await harness.applyAssist(r'''
void f(List<int> values) {
  final doubled = values.m^ap((e) => e * 2).toList();
}
''', 'many_lints.assist.convertIterableMapToCollectionFor');

      expect(result.source, contains('[for(final e in values) e * 2]'));
      expect(result.source, isNot(contains('.map(')));
    });
  });
}
