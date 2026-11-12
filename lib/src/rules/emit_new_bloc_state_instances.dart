import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../bloc_type_checkers.dart';
import '../many_lints_rule.dart';

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

    final emitNames = {
      'emit',
      ...rule.config.stringListOption('additional_methods'),
    };

    body.accept(_EmitFinder(rule, emitNames));
  }
}

class _EmitFinder extends RecursiveAstVisitor<void> {
  final EmitNewBlocStateInstances rule;
  final Set<String> emitNames;

  _EmitFinder(this.rule, this.emitNames);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    if (!emitNames.contains(node.methodName.name)) return;

    final target = node.target;
    if (target != null && target is! ThisExpression) return;

    _reportCurrentStateArgument(node.argumentList);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    super.visitFunctionExpressionInvocation(node);

    // Edge case: a Bloc handler's `emit` is an `Emitter` parameter, invoked as a function value
    if (node.function case SimpleIdentifier(
      :final name,
    ) when emitNames.contains(name)) {
      _reportCurrentStateArgument(node.argumentList);
    }
  }

  void _reportCurrentStateArgument(ArgumentList argumentList) {
    final arguments = argumentList.arguments;
    if (arguments.length != 1) return;

    final argument = arguments.first;
    if (argument is! Expression) return;

    if (_isCurrentState(argument)) rule.reportAtNode(argument);
  }

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
}
