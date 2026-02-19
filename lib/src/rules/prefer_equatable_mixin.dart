import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a class directly extends `Equatable` instead of using
/// `EquatableMixin`. Using the mixin preserves the ability to extend another
/// base class while keeping all equatable features.
class PreferEquatableMixin extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_equatable_mixin',
    'Prefer using EquatableMixin instead of extending Equatable.',
    correctionMessage:
        "Replace 'extends Equatable' with 'with EquatableMixin'.",
  );

  PreferEquatableMixin()
    : super(
        name: 'prefer_equatable_mixin',
        description:
            'Warns when a class extends Equatable instead of using '
            'EquatableMixin.',
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
  final PreferEquatableMixin rule;

  _Visitor(this.rule);

  static const _equatableChecker = TypeChecker.fromName(
    'Equatable',
    packageName: 'equatable',
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return;

    final superclass = extendsClause.superclass;
    final element = superclass.element;
    if (element == null) return;

    if (!_equatableChecker.isExactly(element)) return;

    rule.reportAtNode(extendsClause);
  }
}
