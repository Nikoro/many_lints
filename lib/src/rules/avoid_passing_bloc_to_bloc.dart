import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a Bloc/Cubit class receives another Bloc/Cubit as a constructor
/// parameter, creating a direct dependency between blocs.
///
/// Blocs should only receive information through events and from injected
/// repositories. Direct bloc-to-bloc dependencies bypass the event-driven
/// architecture and create tight coupling.
class AvoidPassingBlocToBloc extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_passing_bloc_to_bloc',
    'Avoid passing a Bloc/Cubit to another Bloc/Cubit.',
    correctionMessage:
        'Use a repository or push the dependency into the presentation layer.',
  );

  AvoidPassingBlocToBloc()
    : super(
        name: 'avoid_passing_bloc_to_bloc',
        description:
            'Warns when a Bloc/Cubit depends on another Bloc/Cubit via '
            'constructor parameters.',
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
  final AvoidPassingBlocToBloc rule;

  _Visitor(this.rule);

  static const _blocBaseChecker = TypeChecker.fromName(
    'BlocBase',
    packageName: 'bloc',
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    // Only check classes that extend BlocBase (Bloc or Cubit)
    if (!_blocBaseChecker.isSuperOf(element)) return;

    // Skip the BlocBase/Bloc/Cubit classes themselves
    if (_blocBaseChecker.isExactly(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is ConstructorDeclaration) {
        _checkConstructor(member);
      }
    }
  }

  void _checkConstructor(ConstructorDeclaration constructor) {
    for (final param in constructor.parameters.parameters) {
      _checkParameter(param);
    }
  }

  void _checkParameter(FormalParameter param) {
    // Get the resolved type of the parameter
    final paramElement = param.declaredFragment?.element;
    if (paramElement == null) return;

    final paramType = paramElement.type;
    if (!_blocBaseChecker.isAssignableFromType(paramType)) return;

    // Report at the parameter name
    final nameToken = param.name;
    if (nameToken != null) {
      rule.reportAtToken(nameToken);
    } else {
      rule.reportAtNode(param);
    }
  }
}
