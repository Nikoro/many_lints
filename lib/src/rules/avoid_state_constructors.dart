import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a `State` subclass declares a constructor with a non-empty body
/// or initializer list.
///
/// Constructors in `State` objects should not contain initialization logic.
/// All setup should go into `State.initState` instead, which is the proper
/// lifecycle method for initialization.
class AvoidStateConstructors extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_state_constructors',
    'Avoid constructors with logic in State classes.',
    correctionMessage: 'Move initialization logic to initState().',
  );

  AvoidStateConstructors()
    : super(
        name: 'avoid_state_constructors',
        description:
            'Warns when a State subclass has a constructor with a '
            'non-empty body or initializer list.',
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
  final AvoidStateConstructors rule;

  _Visitor(this.rule);

  static const _stateChecker = TypeChecker.fromName(
    'State',
    packageName: 'flutter',
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !_stateChecker.isSuperOf(element)) return;

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
