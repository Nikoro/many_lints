import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';

/// Warns if a Notifier class does not have the `Notifier` suffix.
class UseNotifierSuffix extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_notifier_suffix',
    'Use Notifier suffix',
    correctionMessage: 'Ex. {0}Notifier',
  );

  UseNotifierSuffix()
    : super(
        name: 'use_notifier_suffix',
        description:
            'Warns if a Notifier class does not have the Notifier suffix.',
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
  final UseNotifierSuffix rule;

  _Visitor(this.rule);

  static const _notifierChecker = TypeChecker.fromName(
    'Notifier',
    packageName: 'riverpod',
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    if (_notifierChecker.isSuperOf(element) &&
        !node.name.lexeme.endsWith('Notifier')) {
      rule.reportAtToken(node.name, arguments: [node.name.lexeme]);
    }
  }
}
