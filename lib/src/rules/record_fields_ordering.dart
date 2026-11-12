import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ordering_check.dart';

class RecordFieldsOrdering extends ManyLintsRule {
  static const LintCode code = LintCode(
    'record_fields_ordering',
    "The field '{0}' is out of order.",
    correctionMessage:
        'Move it so the record fields stay in the configured order.',
  );

  RecordFieldsOrdering()
    : super(
        name: 'record_fields_ordering',
        description:
            'Warns when record fields are not in the configured order.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addRecordTypeAnnotation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final RecordFieldsOrdering rule;

  _Visitor(this.rule);

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    final configured = rule.config.options['order'];
    if (configured is! String) return;

    final fields = node.namedFields?.fields;
    if (fields == null || fields.length < 2) return;

    final names = fields
        .map((field) => field.name.lexeme)
        .toList(growable: false);

    final mode = OrderingMode.parse(configured);
    final index = firstUnorderedIndex(names, mode);
    if (index == null) return;

    rule.reportAtToken(fields[index].name, arguments: [names[index]]);
  }
}
