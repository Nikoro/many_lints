import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../file_name_utils.dart';
import '../many_lints_rule.dart';

/// Warns when a file under `test/` that declares tests is not named
/// `*_test.dart`.
///
/// `package:test` only runs files matching `*_test.dart`. A file named
/// `user_repository_tests.dart` or `test_user_repository.dart` still compiles,
/// still passes analysis, and is silently never executed — which is the worst
/// failure mode a test can have, because the suite stays green by not running.
///
/// The rule reports only files that actually declare tests (a top-level
/// `main` containing `test(...)`, `testWidgets(...)` or a `group(...)`), so
/// the helpers, fixtures and robots that legitimately live under `test/`
/// without being test files are left alone.
class PreferCorrectTestFileName extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_correct_test_file_name',
    'This file declares tests but is not named with a _test.dart suffix.',
    correctionMessage:
        "Rename it to '{0}_test.dart' so the runner picks it up.",
  );

  PreferCorrectTestFileName()
    : super(
        name: 'prefer_correct_test_file_name',
        description:
            'Warns when a file declaring tests is not named with a _test.dart '
            'suffix.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const _defaultDirectories = {
    'test',
    'integration_test',
    'test_driver',
  };

  final PreferCorrectTestFileName rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = rule.relativePath;
    if (path == null) return;

    final directories = rule.config.nameSetOption(
      'directories',
      defaultValue: _defaultDirectories,
    );
    if (!directories.any((dir) => path.startsWith('$dir/'))) return;

    final name = path.split('/').last;
    if (name.endsWith('_test.dart')) return;

    final main = _mainDeclaration(node);
    if (main == null || !_declaresTests(main)) return;

    final base = fileBaseName(path);
    // Anchored at `main` rather than the unit: a diagnostic spanning the whole
    // file underlines every line of it in an editor.
    rule.reportAtToken(main.name, arguments: [base]);
  }

  FunctionDeclaration? _mainDeclaration(CompilationUnit node) {
    for (final declaration in node.declarations) {
      if (declaration is FunctionDeclaration &&
          declaration.name.lexeme == 'main') {
        return declaration;
      }
    }

    return null;
  }

  bool _declaresTests(FunctionDeclaration main) {
    final finder = _TestCallFinder();
    main.functionExpression.body.accept(finder);

    return finder.found;
  }
}

/// Looks for a call to one of the `package:test` entry points.
///
/// Matched by name rather than by resolved element: `test` and `group` are
/// top-level functions that a project may legitimately re-export through its
/// own harness, and this rule's question is "does this file look like a test
/// file", which the name answers on its own.
class _TestCallFinder extends RecursiveAstVisitor<void> {
  static const _testFunctions = {
    'test',
    'testWidgets',
    'testWidgetsWithAccessibilityChecks',
    'group',
    'patrolTest',
    'patrolWidgetTest',
  };

  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.realTarget == null &&
        _testFunctions.contains(node.methodName.name)) {
      found = true;
      return;
    }

    super.visitMethodInvocation(node);
  }
}
