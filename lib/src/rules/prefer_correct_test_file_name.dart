import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../file_name_utils.dart';
import '../many_lints_rule.dart';

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
    // Edge case: a diagnostic over the whole unit underlines every line in an editor
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
