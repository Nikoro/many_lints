import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a Bloc class declares public members (methods, getters, setters)
/// that are not overrides of parent class members.
///
/// Blocs should only expose state changes through events via the `add` method.
/// Custom public methods, getters, and setters bypass the event-driven pattern
/// and should be avoided.
class AvoidBlocPublicMethods extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_bloc_public_methods',
    "Avoid declaring public members in Bloc classes. Use events via 'add' "
        'instead.',
    correctionMessage:
        'Make this member private or trigger state changes through events.',
  );

  AvoidBlocPublicMethods()
    : super(
        name: 'avoid_bloc_public_methods',
        description:
            'Warns when a Bloc class declares public members beyond overrides.',
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
  final AvoidBlocPublicMethods rule;

  _Visitor(this.rule);

  static const _blocChecker = TypeChecker.fromName('Bloc', packageName: 'bloc');
  static const _cubitChecker = TypeChecker.fromName(
    'Cubit',
    packageName: 'bloc',
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    // Only check classes that extend Bloc (not Cubit or other subtypes)
    if (!_blocChecker.isSuperOf(element)) return;

    // Exclude the Bloc class itself and Cubit subclasses
    if (_blocChecker.isExactly(element)) return;
    if (_cubitChecker.isExactly(element)) return;
    if (_cubitChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is MethodDeclaration) {
        _checkMethodDeclaration(member);
      }
    }
  }

  void _checkMethodDeclaration(MethodDeclaration member) {
    final name = member.name.lexeme;

    // Skip private members
    if (name.startsWith('_')) return;

    // Skip static members
    if (member.isStatic) return;

    // Skip overrides
    if (_hasOverrideAnnotation(member)) return;

    rule.reportAtToken(member.name);
  }

  static bool _hasOverrideAnnotation(MethodDeclaration method) =>
      method.metadata.any((a) => a.name.name == 'override');
}
