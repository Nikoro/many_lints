import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a Bloc/Cubit class accepts a `BuildContext` parameter in its
/// constructor or methods.
///
/// Passing `BuildContext` creates unnecessary coupling between Blocs and
/// widgets. It can also introduce bugs when the context is no longer mounted.
/// Business logic in Blocs/Cubits should remain independent of the UI layer.
class AvoidPassingBuildContextToBlocs extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_passing_build_context_to_blocs',
    'Avoid passing BuildContext to a Bloc/Cubit.',
    correctionMessage:
        'Move the context-dependent logic to the widget layer instead.',
  );

  AvoidPassingBuildContextToBlocs()
    : super(
        name: 'avoid_passing_build_context_to_blocs',
        description:
            'Warns when a Bloc/Cubit accepts BuildContext as a constructor '
            'or method parameter.',
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
  final AvoidPassingBuildContextToBlocs rule;

  _Visitor(this.rule);

  static const _blocBaseChecker = TypeChecker.fromName(
    'BlocBase',
    packageName: 'bloc',
  );

  static const _buildContextChecker = TypeChecker.fromName(
    'BuildContext',
    packageName: 'flutter',
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
        _checkParameters(member.parameters.parameters);
      } else if (member is MethodDeclaration) {
        final params = member.parameters?.parameters;
        if (params != null) {
          _checkParameters(params);
        }
      }
    }
  }

  void _checkParameters(NodeList<FormalParameter> parameters) {
    for (final param in parameters) {
      final paramElement = param.declaredFragment?.element;
      if (paramElement == null) continue;

      final paramType = paramElement.type;
      if (_buildContextChecker.isExactlyType(paramType)) {
        final nameToken = param.name;
        if (nameToken != null) {
          rule.reportAtToken(nameToken);
        } else {
          rule.reportAtNode(param);
        }
      }
    }
  }
}
