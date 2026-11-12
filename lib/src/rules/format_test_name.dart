import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../rule_config.dart';

class FormatTestName extends ManyLintsRule {
  static const LintCode code = LintCode(
    'format_test_name',
    "The test name '{0}' does not match '{1}'.",
    correctionMessage: 'Rename it to match the configured pattern.',
  );

  FormatTestName()
    : super(
        name: 'format_test_name',
        description:
            'Warns when a test description does not match the configured '
            'pattern.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const _testFunctions = {'test', 'testWidgets'};
  static const _groupFunctions = {'group'};

  final FormatTestName rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final pattern = rule.config.patternOption('pattern');
    if (pattern == null) return;

    if (node.realTarget != null) return;

    final name = node.methodName.name;
    final checkGroups = rule.config.boolOption(
      'check_groups',
      defaultValue: false,
    );
    final isTest =
        _testFunctions.contains(name) ||
        (checkGroups && _groupFunctions.contains(name));
    if (!isTest) return;

    final arguments = node.argumentList.arguments;
    if (arguments.isEmpty) return;

    final description = arguments.first;
    if (description is! SimpleStringLiteral) return;

    final value = description.value;
    if (pattern.matchesWholeValue(value)) return;

    rule.reportAtNode(description, arguments: [value, pattern.pattern]);
  }
}
