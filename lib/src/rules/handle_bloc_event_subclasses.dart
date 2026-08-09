import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when a Bloc leaves one of its event subclasses without a handler.
///
/// `on<E>` registration is a runtime lookup, so an unregistered event type has
/// no compile-time consequence: `add(MyEvent())` simply does nothing. No
/// exception, no log, no state change — the feature silently does not work.
///
/// The gap usually appears later, when a new event class is added to a sealed
/// hierarchy and the corresponding `on<E>` is forgotten. Because the compiler
/// cannot see the omission, only a test that exercises that exact event will.
///
/// **Bad:**
/// ```dart
/// sealed class CounterEvent {}
/// class Increment extends CounterEvent {}
/// class Decrement extends CounterEvent {}
///
/// class CounterBloc extends Bloc<CounterEvent, int> {
///   CounterBloc() : super(0) {
///     on<Increment>(...); // `Decrement` is never handled
///   }
/// }
/// ```
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

  static const _blocChecker = TypeChecker.fromName('Bloc', packageName: 'bloc');

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !_blocChecker.isSuperOf(element)) return;

    final eventType = _eventTypeOf(node);
    if (eventType is! InterfaceType) return;

    final eventElement = eventType.element;

    // Only a sealed hierarchy has a knowable set of subtypes. For an open base
    // class a subtype may live in any library, so "every subtype" cannot be
    // computed and a report would be guesswork.
    if (eventElement is! ClassElement || !eventElement.isSealed) return;

    final subclasses = _directSubclassesOf(eventElement);
    if (subclasses.isEmpty) return;

    final handled = _HandlerCollector();
    node.accept(handled);

    for (final subclass in subclasses) {
      // A handler for the base type, or for an ancestor of this subclass,
      // covers it — `on<CounterEvent>` handles every event.
      final covered = handled.types.any(
        (registered) =>
            registered == subclass ||
            subclass.allSupertypes.any((s) => s.element == registered),
      );

      if (!covered) {
        rule.reportAtToken(
          node.namePart.typeName,
          arguments: [subclass.name ?? '?'],
        );
      }
    }
  }

  /// The event type argument of the `extends Bloc<E, S>` clause.
  DartType? _eventTypeOf(ClassDeclaration node) {
    final superclass = node.extendsClause?.superclass;
    final typeArguments = superclass?.typeArguments?.arguments;

    return typeArguments?.firstOrNull?.type;
  }

  /// The sealed subclasses of [element] declared in the same library.
  ///
  /// A sealed type may only be extended within its own library, so this is the
  /// complete set.
  List<InterfaceElement> _directSubclassesOf(ClassElement element) {
    return element.library.classes
        .where(
          (candidate) =>
              candidate != element &&
              candidate.allSupertypes.any((s) => s.element == element),
        )
        .toList();
  }
}

/// Collects the type arguments of every `on<E>(...)` registration.
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
