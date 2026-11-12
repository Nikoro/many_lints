import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

class PreferWidgetPrivateMembers extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_widget_private_members',
    "The widget member '{0}' is public.",
    correctionMessage: 'Make it private: a widget\'s API is its constructor.',
  );

  PreferWidgetPrivateMembers()
    : super(
        name: 'prefer_widget_private_members',
        description: 'Warns when a widget class declares a public method.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const _frameworkCalledMembers = {
    'build',
    'createState',
    'createElement',
    'debugFillProperties',
    'debugDescribeChildren',
    'toStringShort',
    'noSuchMethod',
    'toString',
  };

  final PreferWidgetPrivateMembers rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;
    if (!widgetChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is! MethodDeclaration) continue;
      if (member.isOperator) continue;
      // Edge case: static show(context) is the documented way to open a dialog.
      if (member.isStatic) continue;

      final name = member.name.lexeme;
      if (name.startsWith('_')) continue;
      if (_frameworkCalledMembers.contains(name)) continue;
      if (member.metadata.any((a) => a.name.name == 'override')) continue;
      if (member.metadata.any((a) => a.name.name == 'visibleForTesting')) {
        continue;
      }

      rule.reportAtToken(member.name, arguments: [name]);
    }
  }
}
