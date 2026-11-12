import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferTypeOverVar extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_type_over_var',
    "Prefer an explicit type annotation over 'var'.",
    correctionMessage: 'Try replacing var with an explicit type annotation.',
  );

  PreferTypeOverVar()
    : super(
        name: 'prefer_type_over_var',
        description:
            'Warns when a variable is declared with the var keyword instead of a type.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addVariableDeclarationStatement(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
    registry.addForStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferTypeOverVar rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _checkVariableDeclarationList(node.variables);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _checkVariableDeclarationList(node.variables);
  }

  @override
  void visitForStatement(ForStatement node) {
    final forParts = node.forLoopParts;
    if (forParts is ForPartsWithDeclarations) {
      _checkVariableDeclarationList(forParts.variables);
    }
  }

  void _checkVariableDeclarationList(VariableDeclarationList variables) {
    final keyword = variables.keyword;
    if (keyword == null || keyword.lexeme != 'var') return;
    rule.reportAtToken(keyword);
  }
}
