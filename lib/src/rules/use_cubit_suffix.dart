import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';

/// Warns if a Cubit class does not have the `Cubit` suffix.
class UseCubitSuffix extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_cubit_suffix',
    'Use Cubit suffix',
    correctionMessage: 'Ex. {0}Cubit',
  );

  UseCubitSuffix()
    : super(
        name: 'use_cubit_suffix',
        description: 'Warns if a Cubit class does not have the Cubit suffix.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseCubitSuffix rule;

  _Visitor(this.rule);

  static const _cubitChecker = TypeChecker.fromName(
    'Cubit',
    packageName: 'bloc',
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    if (_cubitChecker.isSuperOf(element) &&
        !node.name.lexeme.endsWith('Cubit')) {
      rule.reportAtToken(node.name, arguments: [node.name.lexeme]);
    }
  }
}
