import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ordering_check.dart';

/// Warns when a function's *named* parameters are not in the configured order.
///
/// A long named-parameter list is a lookup table with the same problem as a
/// long map literal: without an order, checking whether a parameter already
/// exists means reading all of them, and a new one gets appended at the end
/// beside the near-duplicate nobody saw.
///
/// Only named parameters are ordered. Positional parameters are ordered by
/// meaning and by the call sites that depend on them — sorting those would
/// change every caller and break the code.
///
/// **Outside the `pedantic` preset, this rule reports nothing until
/// configured**, since a widget constructor deliberately leads with its most
/// important parameters. Set
/// `order: alphabetical` (or `by_length`, or `alphabetical_case_sensitive`)
/// where a mechanical order is wanted.
///
/// `required` and optional parameters are ordered as independent groups by
/// default. Their relative placement belongs to the SDK's
/// `always_put_required_named_parameters_first`; set `group_required: false`
/// to sort all named parameters together instead.
/// `min_parameters` (default 5) keeps short signatures out of it.
class ParametersOrdering extends ManyLintsRule {
  static const LintCode code = LintCode(
    'parameters_ordering',
    "The parameter '{0}' is out of order.",
    correctionMessage:
        'Move it so the named parameters stay in the configured order.',
  );

  ParametersOrdering()
    : super(
        name: 'parameters_ordering',
        description:
            "Warns when a function's named parameters are not in the "
            'configured order.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addFormalParameterList(this, _Visitor(this));
  }
}

/// Below this, the whole signature is read at once and order is free.
const _defaultMinParameters = 5;

class _Visitor extends SimpleAstVisitor<void> {
  final ParametersOrdering rule;

  _Visitor(this.rule);

  @override
  void visitFormalParameterList(FormalParameterList node) {
    final configured = rule.config.options['order'];
    if (configured is! String) return;

    final minParameters = rule.config.intOption(
      'min_parameters',
      defaultValue: _defaultMinParameters,
    );
    final groupRequired = rule.config.boolOption(
      'group_required',
      defaultValue: true,
    );

    final named = node.parameters
        .where((parameter) => parameter.isNamed)
        .toList(growable: false);
    if (named.length < minParameters) return;

    final mode = OrderingMode.parse(configured);

    if (!groupRequired) {
      _report(named, mode);
      return;
    }

    // Required and optional are sorted as two independent runs. The SDK's
    // always_put_required_named_parameters_first owns their relative placement.
    _report(named.where((p) => p.isRequired).toList(growable: false), mode);
    _report(named.where((p) => !p.isRequired).toList(growable: false), mode);
  }

  void _report(List<FormalParameter> parameters, OrderingMode mode) {
    final names = <String>[];
    for (final parameter in parameters) {
      final name = parameter.name?.lexeme;
      // A parameter with no name token cannot be ordered, and its position
      // relative to the others is not something the rule can judge.
      if (name == null) return;
      names.add(name);
    }

    final index = firstUnorderedIndex(names, mode);
    if (index == null) return;

    final token = parameters[index].name;
    if (token == null) return;

    rule.reportAtToken(token, arguments: [names[index]]);
  }
}
