import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';

class AvoidNotifierConstructors extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_notifier_constructors',
    'Avoid constructors with logic in Notifier classes.',
    correctionMessage: 'Move initialization logic to the build() method.',
  );

  AvoidNotifierConstructors()
    : super(
        name: 'avoid_notifier_constructors',
        description:
            'Warns when a Notifier or AsyncNotifier subclass has a '
            'constructor with a non-empty body or initializer list.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidNotifierConstructors rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !notifierChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is! ConstructorDeclaration) continue;

      final hasBody =
          member.body is BlockFunctionBody &&
          (member.body as BlockFunctionBody).block.statements.isNotEmpty;

      final hasInitializers = member.initializers.any(
        (i) => i is! SuperConstructorInvocation,
      );

      if (hasBody || hasInitializers) {
        rule.reportAtNode(member);
      }
    }
  }
}
