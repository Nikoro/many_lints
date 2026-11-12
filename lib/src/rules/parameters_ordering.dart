import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ordering_check.dart';

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

    _report(named.where((p) => p.isRequired).toList(growable: false), mode);
    _report(named.where((p) => !p.isRequired).toList(growable: false), mode);
  }

  void _report(List<FormalParameter> parameters, OrderingMode mode) {
    final names = <String>[];
    for (final parameter in parameters) {
      final name = parameter.name?.lexeme;
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
