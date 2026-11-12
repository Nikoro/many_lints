import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ordering_check.dart';

class PatternFieldsOrdering extends ManyLintsRule {
  static const LintCode code = LintCode(
    'pattern_fields_ordering',
    "The field '{0}' is out of order.",
    correctionMessage:
        'Move it so the pattern fields stay in the configured order.',
  );

  PatternFieldsOrdering()
    : super(
        name: 'pattern_fields_ordering',
        description:
            'Warns when pattern fields are not in the configured order.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addObjectPattern(this, visitor);
    registry.addRecordPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PatternFieldsOrdering rule;

  _Visitor(this.rule);

  @override
  void visitObjectPattern(ObjectPattern node) => _check(node.fields);

  @override
  void visitRecordPattern(RecordPattern node) => _check(node.fields);

  void _check(List<PatternField> fields) {
    final configured = rule.config.options['order'];
    if (configured is! String) return;

    if (fields.length < 2) return;

    final names = <String>[];
    for (final field in fields) {
      final name = field.effectiveName;
      if (name == null) return;
      names.add(name);
    }

    final mode = OrderingMode.parse(configured);
    final index = firstUnorderedIndex(names, mode);
    if (index == null) return;

    rule.reportAtNode(fields[index], arguments: [names[index]]);
  }
}
