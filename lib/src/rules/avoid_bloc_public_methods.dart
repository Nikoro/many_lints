import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ast_node_analysis.dart';
import '../bloc_type_checkers.dart';

class AvoidBlocPublicMethods extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_bloc_public_methods',
    "Avoid declaring public members in Bloc classes. Use events via 'add' "
        'instead.',
    correctionMessage:
        'Make this member private or trigger state changes through events.',
  );

  AvoidBlocPublicMethods()
    : super(
        name: 'avoid_bloc_public_methods',
        description:
            'Warns when a Bloc class declares public members beyond overrides.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBlocPublicMethods rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    if (!blocChecker.isSuperOf(element)) return;

    if (blocChecker.isExactly(element)) return;
    if (cubitChecker.isExactly(element)) return;
    if (cubitChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is MethodDeclaration) {
        _checkMethodDeclaration(member);
      }
    }
  }

  void _checkMethodDeclaration(MethodDeclaration member) {
    final name = member.name.lexeme;

    if (name.startsWith('_')) return;

    if (member.isStatic) return;

    if (hasOverrideAnnotation(member)) return;

    rule.reportAtToken(member.name);
  }
}
