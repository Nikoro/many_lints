import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:many_lints/src/assists/convert_iterable_map_to_collection_for.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(ConvertIterableMapToCollectionForTest),
  );
}

@reflectiveTest
class ConvertIterableMapToCollectionForTest extends PubPackageResolutionTest {
  Future<String?> _applyAssist(String content, String target) async {
    final file = newFile('$testPackageLibPath/test.dart', content);
    final resolvedUnit = await resolveFile(file.path);
    final resolvedLibrary =
        await resolvedUnit.session.getResolvedLibraryByElement(
              resolvedUnit.libraryElement,
            )
            as ResolvedLibraryResult;

    final offset = content.indexOf(target);
    assert(offset != -1, 'Target "$target" not found in content');

    final context = CorrectionProducerContext.createResolved(
      libraryResult: resolvedLibrary,
      unitResult: resolvedUnit,
      selectionOffset: offset,
      selectionLength: target.length,
    );

    final assist = ConvertIterableMapToCollectionFor(context: context);
    final builder = ChangeBuilder(session: resolvedUnit.session);
    await assist.compute(builder);

    final change = builder.sourceChange;
    if (change.edits.isEmpty) return null;

    var result = content;
    // Apply edits in reverse order to maintain offsets
    final edits = change.edits.first.edits.toList()
      ..sort((a, b) => b.offset.compareTo(a.offset));
    for (final edit in edits) {
      result = result.replaceRange(
        edit.offset,
        edit.offset + edit.length,
        edit.replacement,
      );
    }
    return result;
  }

  Future<void> test_mapToList_arrowBody() async {
    final result = await _applyAssist(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.map((e) => e * 2).toList();
}
''', 'map');
    expect(result, contains('[for(final e in list) e * 2]'));
  }

  Future<void> test_mapToSet_arrowBody() async {
    final result = await _applyAssist(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.map((e) => e * 2).toSet();
}
''', 'map');
    expect(result, contains('{for(final e in list) e * 2}'));
  }

  Future<void> test_mapWithoutCollect_defaultsToList() async {
    final result = await _applyAssist(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.map((e) => e * 2);
}
''', 'map');
    expect(result, contains('[for(final e in list) e * 2]'));
  }

  Future<void> test_mapWithBlockBody() async {
    final result = await _applyAssist(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.map((e) { return e * 2; }).toList();
}
''', 'map');
    expect(result, contains('[for(final e in list) e * 2]'));
  }

  Future<void> test_notApplicable_multipleStatements() async {
    final result = await _applyAssist(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.map((e) { print(e); return e * 2; }).toList();
}
''', 'map');
    expect(result, isNull);
  }

  Future<void> test_notApplicable_multipleParameters() async {
    final result = await _applyAssist(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.where((e) => e > 1).toList();
}
''', 'where');
    expect(result, isNull);
  }

  Future<void> test_notApplicable_notIterable() async {
    final result = await _applyAssist(r'''
class NotIterable {
  NotIterable map(Function f) => this;
  List toList() => [];
}
void f() {
  final x = NotIterable();
  final result = x.map((e) => e).toList();
}
''', 'map');
    expect(result, isNull);
  }

  Future<void> test_cursorOnTarget() async {
    final result = await _applyAssist(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.map((e) => e * 2).toList();
}
''', 'list.map');
    expect(result, contains('[for(final e in list) e * 2]'));
  }

  Future<void> test_mapWithNamedParameter() async {
    final result = await _applyAssist(r'''
void f() {
  final items = [1, 2, 3];
  final result = items.map((item) => item.toString()).toList();
}
''', 'map');
    expect(result, contains('[for(final item in items) item.toString()]'));
  }

  Future<void> test_notApplicable_noMethodInvocation() async {
    final result = await _applyAssist(r'''
void f() {
  final x = 42;
}
''', 'final');
    expect(result, isNull);
  }
}
