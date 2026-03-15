import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_closest_build_context.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(UseClosestBuildContextTest),
  );
}

@reflectiveTest
class UseClosestBuildContextTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseClosestBuildContext();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class BuildContext {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
class Builder extends Widget {
  Builder({required Widget Function(BuildContext context) builder});
}
class LayoutBuilder extends Widget {
  LayoutBuilder({required Widget Function(BuildContext context, Object constraints) builder});
}
class Text extends Widget {
  Text(String data);
}

class OptionalCtxBuilder extends Widget {
  OptionalCtxBuilder({required Widget Function([BuildContext context]) builder});
}
''');
    super.setUp();
  }

  Future<void> test_outerContextUsedInBuilder() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (_) {
      return _buildMyWidget(context);
    });
  }
  Widget _buildMyWidget(BuildContext ctx) => Text('hello');
}
''',
      [lint(193, 7)],
    );
  }

  Future<void> test_outerContextUsedInLayoutBuilder() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      return _buildMyWidget(context);
    });
  }
  Widget _buildMyWidget(BuildContext ctx) => Text('hello');
}
''',
      [lint(212, 7)],
    );
  }

  Future<void> test_outerContextUsedInPropertyAccess() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (_) {
      context.hashCode;
      return Text('hello');
    });
  }
}
''',
      [lint(171, 7)],
    );
  }

  Future<void> test_innerContextUsed_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return _buildMyWidget(context);
    });
  }
  Widget _buildMyWidget(BuildContext ctx) => Text('hello');
}
''');
  }

  Future<void> test_innerContextNamedDifferently_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (innerContext) {
      return _buildMyWidget(innerContext);
    });
  }
  Widget _buildMyWidget(BuildContext ctx) => Text('hello');
}
''');
  }

  Future<void> test_noNestedBuilder_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildMyWidget(context);
  }
  Widget _buildMyWidget(BuildContext ctx) => Text('hello');
}
''');
  }

  Future<void> test_multipleOuterContextUsages() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (_) {
      context.hashCode;
      context.hashCode;
      return Text('hello');
    });
  }
}
''',
      [lint(171, 7), lint(195, 7)],
    );
  }

  Future<void> test_closureWithoutBuildContextParam_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [1, 2, 3];
    items.forEach((item) {
      context.hashCode;
    });
    return Text('hello');
  }
}
''');
  }

  Future<void> test_namedCallback() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget myBuilder(BuildContext _) {
      return _buildMyWidget(context);
    }
    return Builder(builder: myBuilder);
  }
  Widget _buildMyWidget(BuildContext ctx) => Text('hello');
}
''',
      [lint(198, 7)],
    );
  }

  Future<void> test_defaultFormalParam_buildContext() async {
    // Tests DefaultFormalParameter path (lines 83-86)
    // Optional positional parameter wraps SimpleFormalParameter in
    // DefaultFormalParameter
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OptionalCtxBuilder(builder: ([BuildContext? innerCtx]) {
      return _buildMyWidget(context);
    });
  }
  Widget _buildMyWidget(BuildContext ctx) => Text('hello');
}
''',
      [lint(228, 7)],
    );
  }

  Future<void> test_outerContextUsedAsPrefixedIdentifier() async {
    // Tests PrefixedIdentifier path in _OuterContextUsageFinder (line 159)
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (_) {
      context.hashCode;
      return Text('hello');
    });
  }
}
''',
      [lint(171, 7)],
    );
  }

  Future<void>
  test_tripleNestedClosure_innerHasBuildContext_stopsSearch() async {
    // Tests visitFunctionExpression in _OuterContextUsageFinder (lines 169-180)
    // The middle closure has BuildContext, so usage in deepest closure should
    // not flag the outermost context.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (innerCtx) {
      return Builder(builder: (deepCtx) {
        return Text('hello');
      });
    });
  }
}
''');
  }

  Future<void> test_nestedClosureWithoutBuildContext_continuesSearch() async {
    // Tests visitFunctionExpression in _OuterContextUsageFinder (line 180)
    // The nested closure does NOT have BuildContext, so search continues.
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (_) {
      final fn = () {
        context.hashCode;
      };
      return Text('hello');
    });
  }
}
''',
      [lint(195, 7)],
    );
  }

  Future<void> test_nestedClosureWithBuildContext_reportsDeeper() async {
    // The _NestedContextFinder processes each closure level independently.
    // The deepest closure has its own BuildContext (deepCtx) but references
    // the outer `context`, so it gets reported.
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (_) {
      return Builder(builder: (deepCtx) {
        context.hashCode;
        return Text('hello');
      });
    });
  }
}
''',
      [lint(215, 7)],
    );
  }
}
