import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../bloc_type_checkers.dart';
import '../many_lints_rule.dart';

class HandleBlocEventSubclasses extends ManyLintsRule {
  static const LintCode code = LintCode(
    'handle_bloc_event_subclasses',
    "Event '{0}' has no handler registered.",
    correctionMessage:
        "Add 'on<{0}>(...)' — an unregistered event is silently ignored at "
        'runtime.',
  );

  HandleBlocEventSubclasses()
    : super(
        name: 'handle_bloc_event_subclasses',
        description:
            'Warns when a Bloc does not register a handler for every subtype '
            'of its event type.',
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
  final HandleBlocEventSubclasses rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !blocChecker.isSuperOf(element)) return;

    final eventType = _eventTypeOf(node);
    if (eventType is! InterfaceType) return;

    final eventElement = eventType.element;

    if (eventElement is! ClassElement || !eventElement.isSealed) return;

    final subclasses = _sameLibrarySubtypesOf(eventElement);
    if (subclasses.isEmpty) return;

    final handled = _HandlerCollector();
    node.accept(handled);

    for (final subclass in subclasses) {
      if (!_isHandled(subclass, handled.types)) {
        rule.reportAtToken(
          node.namePart.typeName,
          arguments: [subclass.name ?? '?'],
        );
      }
    }
  }

  bool _isHandled(
    InterfaceElement subclass,
    Set<InterfaceElement> registeredTypes,
  ) => registeredTypes.any(
    (registered) =>
        registered == subclass ||
        subclass.allSupertypes.any((s) => s.element == registered),
  );

  DartType? _eventTypeOf(ClassDeclaration node) {
    final superclass = node.extendsClause?.superclass;
    final typeArguments = superclass?.typeArguments?.arguments;

    return typeArguments?.firstOrNull?.type;
  }

  // Edge case: a sealed type is extended only inside its own library, so this set is complete
  List<InterfaceElement> _sameLibrarySubtypesOf(ClassElement element) {
    return element.library.classes
        .where(
          (candidate) =>
              candidate != element &&
              candidate.allSupertypes.any((s) => s.element == element),
        )
        .toList();
  }
}

class _HandlerCollector extends RecursiveAstVisitor<void> {
  final Set<InterfaceElement> types = {};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    if (node.methodName.name != 'on') return;

    final target = node.target;
    if (target != null && target is! ThisExpression) return;

    final argument = node.typeArguments?.arguments.firstOrNull?.type;
    if (argument is InterfaceType) types.add(argument.element);
  }
}
