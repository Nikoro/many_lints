import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when a widget's callback argument holds a long inline closure.
///
/// A closure written inline inside `build` puts logic in the middle of a
/// layout description, where it is read by anyone scanning for the tree's
/// shape and re-created on every rebuild. Extracting it to a method leaves the
/// tree readable and gives the behaviour a name.
///
/// The threshold is what makes this usable: `onTap: () => _submit()` is a
/// tear-off in all but spelling and reporting it would be noise, so only
/// closures whose body exceeds `max_statements` (default 3) are reported. A
/// closure that takes the callback's parameters and does something small with
/// them is the shape this rule is happy with.
///
/// Not to be confused with `avoid_returning_widgets`, which is about a
/// function *returning* a widget. This one is about behaviour attached to one.
class PreferExtractingCallbacks extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_extracting_callbacks',
    'This inline callback holds {0} statements.',
    correctionMessage:
        'Extract it to a method so the widget tree stays readable.',
  );

  PreferExtractingCallbacks()
    : super(
        name: 'prefer_extracting_callbacks',
        description:
            "Warns when a widget's callback argument holds a long inline "
            'closure.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferExtractingCallbacks rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !widgetChecker.isSuperOf(element)) return;

    final maxStatements = rule.config.intOption(
      'max_statements',
      defaultValue: 3,
    );
    final ignored = rule.config.nameSetOption(
      'ignored_parameters',
      defaultValue: const {'builder', 'itemBuilder', 'separatorBuilder'},
    );

    for (final argument in node.argumentList.arguments) {
      if (argument is! NamedArgument) continue;

      final name = argument.name.lexeme;
      // A `builder` is not a callback attached to a widget: its whole job is
      // to describe a subtree, and extracting it to a method would trip
      // `avoid_returning_widgets` instead.
      if (ignored.contains(name)) continue;

      final closure = argument.argumentExpression;
      if (closure is! FunctionExpression) continue;

      final body = closure.body;
      if (body is! BlockFunctionBody) continue;

      final statements = body.block.statements.length;
      if (statements <= maxStatements) continue;

      rule.reportAtNode(closure, arguments: ['$statements']);
    }
  }
}
