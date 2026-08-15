import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a class explicitly extends `Object`.
///
/// Every Dart class extends `Object` already, so the clause states the default
/// while looking like a decision. A reader who sees an `extends` expects the
/// superclass to matter, and has to recall that this one does not.
class AvoidUnnecessaryExtends extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_extends',
    "Extending 'Object' is the default.",
    correctionMessage: "Remove the 'extends Object' clause.",
  );

  AvoidUnnecessaryExtends()
    : super(
        name: 'avoid_unnecessary_extends',
        description:
            'Warns when a class explicitly extends Object, which every class '
            'does anyway.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryExtends rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return;

    final superclass = extendsClause.superclass;
    if (superclass.name.lexeme != 'Object') return;

    // A user-declared `Object` in scope would shadow `dart:core`'s, and
    // extending that one is meaningful. The resolved type says which it is.
    final type = superclass.type;
    if (type == null || !type.isDartCoreObject) return;

    rule.reportAtNode(extendsClause);
  }
}
