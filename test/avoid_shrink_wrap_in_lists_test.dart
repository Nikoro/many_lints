import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_shrink_wrap_in_lists.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidShrinkWrapInListsTest),
  );
}

@reflectiveTest
class AvoidShrinkWrapInListsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidShrinkWrapInLists();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Key {
  const Key(String value);
}

abstract class Widget {
  const Widget({Key? key});
}

class ListView extends Widget {
  final bool shrinkWrap;
  const ListView({
    super.key,
    this.shrinkWrap = false,
    List<Widget> children = const [],
  });

  const factory ListView.builder({
    Key? key,
    bool shrinkWrap,
    required int itemCount,
    required Widget Function(int) itemBuilder,
  }) = _ListViewBuilder;

  const factory ListView.separated({
    Key? key,
    bool shrinkWrap,
    required int itemCount,
    required Widget Function(int) itemBuilder,
    required Widget Function(int) separatorBuilder,
  }) = _ListViewSeparated;
}

class _ListViewBuilder extends ListView {
  const _ListViewBuilder({
    super.key,
    super.shrinkWrap,
    required int itemCount,
    required Widget Function(int) itemBuilder,
  });
}

class _ListViewSeparated extends ListView {
  const _ListViewSeparated({
    super.key,
    super.shrinkWrap,
    required int itemCount,
    required Widget Function(int) itemBuilder,
    required Widget Function(int) separatorBuilder,
  });
}

class Column extends Widget {
  final List<Widget> children;
  const Column({super.key, this.children = const []});
}

class Text extends Widget {
  final String data;
  const Text(this.data, {super.key});
}
''');
    super.setUp();
  }

  // --- Cases that SHOULD trigger the lint ---

  Future<void> test_listViewWithShrinkWrapTrue() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
final widget = ListView(shrinkWrap: true);
''',
      [lint(63, 16)],
    );
  }

  Future<void> test_listViewWithShrinkWrapTrueAndOtherArgs() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
final widget = ListView(
  key: Key('k'),
  shrinkWrap: true,
  children: [Text('a')],
);
''',
      [lint(83, 16)],
    );
  }

  Future<void> test_listViewBuilderWithShrinkWrapTrue() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
final widget = ListView.builder(
  shrinkWrap: true,
  itemCount: 10,
  itemBuilder: (i) => Text('$i'),
);
''',
      [lint(74, 16)],
    );
  }

  Future<void> test_listViewSeparatedWithShrinkWrapTrue() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
final widget = ListView.separated(
  shrinkWrap: true,
  itemCount: 10,
  itemBuilder: (i) => Text('$i'),
  separatorBuilder: (i) => Text('-'),
);
''',
      [lint(76, 16)],
    );
  }

  Future<void> test_listViewNestedInColumn() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
final widget = Column(
  children: [
    ListView(shrinkWrap: true),
  ],
);
''',
      [lint(89, 16)],
    );
  }

  // --- Cases that should NOT trigger the lint ---

  Future<void> test_listViewWithoutShrinkWrap() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
final widget = ListView();
''');
  }

  Future<void> test_listViewWithShrinkWrapFalse() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
final widget = ListView(shrinkWrap: false);
''');
  }

  Future<void> test_listViewBuilderWithoutShrinkWrap() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
final widget = ListView.builder(
  itemCount: 10,
  itemBuilder: (i) => Text('$i'),
);
''');
  }

  Future<void> test_columnWidget() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
final widget = Column(children: [Text('hello')]);
''');
  }
}
