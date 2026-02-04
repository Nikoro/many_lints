import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';

/// Warns if a Bloc class does not have the `Bloc` suffix.
class UseBlocSuffix extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_bloc_suffix',
    'Use Bloc suffix',
    correctionMessage: 'Ex. {0}Bloc',
  );

  UseBlocSuffix()
    : super(
        name: 'use_bloc_suffix',
        description: 'Warns if a Bloc class does not have the Bloc suffix.',
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
  final UseBlocSuffix rule;

  _Visitor(this.rule);

  static const _blocChecker = TypeChecker.fromName('Bloc', packageName: 'bloc');

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    if (_blocChecker.isSuperOf(element) && !node.name.lexeme.endsWith('Bloc')) {
      rule.reportAtToken(node.name, arguments: [node.name.lexeme]);
    }
  }
}
