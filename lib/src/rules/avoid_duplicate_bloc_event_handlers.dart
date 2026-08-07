import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when the same event type is registered with `on<E>` more than once.
///
/// `Bloc.on<E>` asserts that each event type has exactly one handler and
/// throws a `StateError` when a second registration for the same type is
/// added. Because that happens in the constructor, the failure surfaces the
/// first time the bloc is created rather than where the duplicate was
/// written.
class AvoidDuplicateBlocEventHandlers extends AnalysisRule {
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
  void registerNodeProcessors(
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

  static const _blocChecker = TypeChecker.fromName('Bloc', packageName: 'bloc');

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !_blocChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    // Registrations are collected per class rather than per constructor:
    // two constructors each registering the same event never both run.
    for (final member in body.members) {
      if (member is! ConstructorDeclaration) continue;
      final finder = _EventHandlerFinder(rule);
      member.body.visitChildren(finder);
    }
  }
}

/// Collects `on<E>(...)` registrations and reports repeats of the same `E`.
class _EventHandlerFinder extends RecursiveAstVisitor<void> {
  final AvoidDuplicateBlocEventHandlers rule;

  /// Elements of event types already registered. Keying on the element
  /// rather than the type makes two references to the same event compare
  /// equal even when written with different import prefixes.
  final Set<Element> _seen = {};

  _EventHandlerFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    if (node.methodName.name != 'on') return;

    // Only an unqualified `on<E>(...)` or `this.on<E>(...)`.
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
