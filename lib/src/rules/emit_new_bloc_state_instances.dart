import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../bloc_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when `emit` is handed the current state object instead of a new
/// instance.
///
/// `BlocBase.emit` compares the incoming state to the current one with `==`
/// and drops it when they are equal. Passing `state` back — directly, or after
/// mutating a field on it — is therefore a no-op: no listener rebuilds, and
/// the UI silently keeps showing the old data.
///
/// The failure is quiet. Nothing throws, the handler runs to completion, and
/// the bug looks like a rendering problem rather than a state one.
///
/// **Bad:**
/// ```dart
/// void refresh() {
///   state.items.add(item);
///   emit(state); // dropped — same instance, so `==` holds
/// }
/// ```
///
/// **Good:**
/// ```dart
/// void refresh() {
///   emit(state.copyWith(items: [...state.items, item]));
/// }
/// ```
class EmitNewBlocStateInstances extends ManyLintsRule {
  static const LintCode code = LintCode(
    'emit_new_bloc_state_instances',
    'This emits the existing state object rather than a new instance.',
    correctionMessage:
        "Emit a new instance, for example 'state.copyWith(...)', since emit "
        'ignores a state equal to the current one.',
  );

  EmitNewBlocStateInstances()
    : super(
        name: 'emit_new_bloc_state_instances',
        description:
            'Warns when emit receives the existing state object instead of a '
            'newly created instance.',
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
  final EmitNewBlocStateInstances rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !blocOrCubitChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    // A wrapper such as `safeEmit(...)` that forwards to `emit` has the same
    // no-op hazard, but only the project knows it exists. Default `[]` keeps
    // `emit` as the only name, matching the sibling bloc rules.
    final emitNames = {
      'emit',
      ...rule.config.stringListOption('additional_methods'),
    };

    body.accept(_EmitFinder(rule, emitNames));
  }
}

/// Finds `emit(...)` calls whose argument is the current state.
class _EmitFinder extends RecursiveAstVisitor<void> {
  final EmitNewBlocStateInstances rule;
  final Set<String> emitNames;

  _EmitFinder(this.rule, this.emitNames);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    // Cubit form: `emit(...)` resolves to the inherited method.
    if (!emitNames.contains(node.methodName.name)) return;

    final target = node.target;
    if (target != null && target is! ThisExpression) return;

    _check(node.argumentList);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    super.visitFunctionExpressionInvocation(node);

    // Bloc form: `emit` is the handler's `Emitter` parameter, so calling it
    // parses as an invocation of a function-typed expression.
    if (node.function case SimpleIdentifier(
      :final name,
    ) when emitNames.contains(name)) {
      _check(node.argumentList);
    }
  }

  void _check(ArgumentList argumentList) {
    final arguments = argumentList.arguments;
    if (arguments.length != 1) return;

    final argument = arguments.first;
    if (argument is! Expression) return;

    if (_isCurrentState(argument)) rule.reportAtNode(argument);
  }

  /// Whether [expression] is the current state itself rather than a value
  /// derived from it.
  ///
  /// Only the bare reads `state` and `this.state` qualify. Anything built from
  /// the state — `state.copyWith(...)`, `state + 1`, `state.items.first` — is
  /// a different object and is left alone.
  bool _isCurrentState(Expression expression) => switch (expression) {
    SimpleIdentifier(name: 'state') => true,
    PropertyAccess(
      target: ThisExpression(),
      propertyName: SimpleIdentifier(name: 'state'),
    ) =>
      true,
    ParenthesizedExpression(:final expression) => _isCurrentState(expression),
    _ => false,
  };

  // Note: `visitFunctionExpression` is deliberately *not* overridden to stop
  // traversal, unlike the after-await rules in this package. Those stop at a
  // closure because its guards cannot be reasoned about from the enclosing
  // scope; here there is nothing to reason about — `emit(state)` is a no-op
  // whenever it runs, so a callback body is worth descending into.
}
