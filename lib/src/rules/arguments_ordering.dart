import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ordering_check.dart';

/// Warns when a call's *named* arguments are not in the configured order.
///
/// A call site with a dozen named arguments is a lookup table, and an
/// unordered one has to be read end to end to answer "is this already set?".
/// Ordering also keeps a diff honest: a new argument lands in the middle where
/// it can be seen, rather than appended beside a near-duplicate nobody noticed.
///
/// **Positional arguments are never ordered**, since their order is the call's
/// meaning and reordering them changes what it does.
///
/// **This rule reports nothing until configured**, because a widget call
/// deliberately leads with the arguments that matter most. Set
/// `order: alphabetical` (or `by_length`, or `alphabetical_case_sensitive`)
/// where a mechanical order is genuinely wanted.
///
/// `min_arguments` (default 5) keeps short calls, where order carries no cost,
/// out of it.
class ArgumentsOrdering extends ManyLintsRule {
  static const LintCode code = LintCode(
    'arguments_ordering',
    "The argument '{0}' is out of order.",
    correctionMessage:
        'Move it so the named arguments stay in the configured order.',
  );

  ArgumentsOrdering()
    : super(
        name: 'arguments_ordering',
        description:
            'Warns when named arguments are not in the configured order.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addArgumentList(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final ArgumentsOrdering rule;

  _Visitor(this.rule);

  @override
  void visitArgumentList(ArgumentList node) {
    final configured = rule.config.options['order'];
    if (configured is! String) return;

    final minArguments = rule.config.intOption(
      'min_arguments',
      defaultValue: 5,
    );

    final named = node.arguments.whereType<NamedArgument>().toList(
      growable: false,
    );
    if (named.length < minArguments) return;

    final names = named
        .map((argument) => argument.name.lexeme)
        .toList(growable: false);

    final mode = OrderingMode.parse(configured);
    final index = firstUnorderedIndex(names, mode);
    if (index == null) return;

    rule.reportAtToken(named[index].name, arguments: [names[index]]);
  }
}
