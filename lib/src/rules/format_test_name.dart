import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../rule_config.dart';

/// Warns when a test description does not match the configured pattern.
///
/// A test name is read far more often than it is written — in CI output, in a
/// failure report, in a bisect log — and it is read without the code beside
/// it. A house pattern (`should ...`, `given ... when ... then ...`) makes
/// that output scannable, and makes a test whose name no longer describes its
/// body visible.
///
/// **This rule reports nothing until configured**, because the right pattern
/// is a house style with no defensible default. The common one is:
///
/// ```yaml
/// rules:
///   format_test_name:
///     pattern: 'should .*'
/// ```
///
/// Only the description of `test(...)` and `testWidgets(...)` is checked.
/// `group(...)` names are deliberately exempt by default — a group names a
/// subject (`UserRepository`, `when offline`) rather than an expectation, so
/// holding it to the same sentence pattern fights the convention it enforces.
/// Set `check_groups: true` to include them.
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
    // Silent until the project picks a pattern: there is no defensible default.
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
    // A non-literal description — a constant, an interpolation, a variable —
    // cannot be checked without evaluating it, and a rule that reports what it
    // cannot read would flag every parameterised test.
    if (description is! SimpleStringLiteral) return;

    final value = description.value;
    if (pattern.matchesWholeValue(value)) return;

    rule.reportAtNode(description, arguments: [value, pattern.pattern]);
  }
}
