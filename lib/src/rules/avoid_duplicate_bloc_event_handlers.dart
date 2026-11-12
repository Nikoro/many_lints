import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../bloc_type_checkers.dart';
import '../many_lints_rule.dart';

class AvoidDuplicateBlocEventHandlers extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_bloc_event_handlers',
    "The event '{0}' already has a handler registered.",
    correctionMessage:
        'Bloc allows one handler per event type and throws at runtime on a '
        'duplicate. Merge the handlers, or register a different event type.',
  );

  AvoidDuplicateBlocEventHandlers()
    : super(
        name: 'avoid_duplicate_bloc_event_handlers',
        description:
            'Warns when the same event type is registered more than once '
            'with Bloc.on, which throws at runtime.',
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
  final AvoidDuplicateBlocEventHandlers rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !blocChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is! ConstructorDeclaration) continue;
      // Edge case: one finder per constructor, as two constructors never both run
      final finder = _EventHandlerFinder(rule);
      member.body.visitChildren(finder);
    }
  }
}

class _EventHandlerFinder extends RecursiveAstVisitor<void> {
  final AvoidDuplicateBlocEventHandlers rule;

  // Edge case: keyed by element, so one event written with two import prefixes still collides
  final Set<Element> _seen = {};

  _EventHandlerFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    final name = node.methodName.name;
    if (name != 'on' &&
        !rule.config.stringListOption('additional_methods').contains(name)) {
      return;
    }

    final target = node.target;
    if (target != null && target is! ThisExpression) return;

    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.length != 1) return;

    final type = typeArguments.first.type;
    if (type is! InterfaceType) return;

    if (!_seen.add(type.element)) {
      rule.reportAtNode(node.methodName, arguments: [type.getDisplayString()]);
    }
  }
}
