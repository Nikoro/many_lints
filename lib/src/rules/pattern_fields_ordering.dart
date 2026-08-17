import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ordering_check.dart';

/// Warns when an object or record pattern's named fields are not in the
/// configured order.
///
/// A destructuring pattern reads as a small table of what is being pulled out,
/// and the same object is often destructured in several places. When each
/// spelling picks its own order, the reader cannot compare two of them at a
/// glance to see which fields one takes and the other does not.
///
/// **Outside the `pedantic` preset, this rule reports nothing until
/// configured.** Set `order: alphabetical` (or `by_length`, or
/// `alphabetical_case_sensitive`) to adopt one.
///
/// Only fields with an explicit or inferable name are ordered; a positional
/// field in a record pattern is identified by position and is left alone.
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
      // `effectiveName` covers both `:name` shorthand and `name: pattern`; a
      // positional field has none, and one unnamed field makes the list
      // unorderable rather than partially ordered.
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
