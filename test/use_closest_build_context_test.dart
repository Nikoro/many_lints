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
}
