import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';

/// Warns when a file contains more than one public widget class.
/// Private widgets (prefixed with underscore) are ignored.
class PreferSingleWidgetPerFile extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_single_widget_per_file',
    'Only one public widget per file. Move additional widgets to separate files.',
    correctionMessage: 'Move this widget to its own file.',
  );

  PreferSingleWidgetPerFile()
    : super(
        name: 'prefer_single_widget_per_file',
        description:
            'Warns when a file contains more than one public widget class.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSingleWidgetPerFile rule;

  _Visitor(this.rule);

  static const _widgetChecker = TypeChecker.fromName(
    'Widget',
    packageName: 'flutter',
  );

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final publicWidgets = <ClassDeclaration>[];

    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      // Skip private widgets
      final name = declaration.namePart.typeName.lexeme;
      if (name.startsWith('_')) continue;

      final element = declaration.declaredFragment?.element;
      if (element == null) continue;

      if (_widgetChecker.isSuperOf(element)) {
        publicWidgets.add(declaration);
      }
    }

    // Report all public widgets after the first one
    if (publicWidgets.length > 1) {
      for (var i = 1; i < publicWidgets.length; i++) {
        rule.reportAtToken(publicWidgets[i].namePart.typeName);
      }
    }
  }
}
