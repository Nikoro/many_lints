import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ordering_check.dart';

class EnumConstantsOrdering extends ManyLintsRule {
  static const LintCode code = LintCode(
    'enum_constants_ordering',
    "'{0}' is out of order.",
    correctionMessage: 'Move it so the constants stay in the configured order.',
  );

  EnumConstantsOrdering()
    : super(
        name: 'enum_constants_ordering',
        description:
            "Warns when an enum's constants are not in the configured order.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addEnumDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final EnumConstantsOrdering rule;

  _Visitor(this.rule);

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    final configured = rule.config.options['order'];
    if (configured is! String) return;

    final mode = OrderingMode.parse(configured);
    final constants = node.body.constants;
    final names = constants
        .map((constant) => constant.name.lexeme)
        .toList(growable: false);

    final index = firstUnorderedIndex(names, mode);
    if (index == null) return;

    rule.reportAtToken(constants[index].name, arguments: [names[index]]);
  }
}
