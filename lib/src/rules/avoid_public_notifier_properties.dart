import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../riverpod_type_checkers.dart';

/// Warns when a `Notifier` or `AsyncNotifier` subclass declares public
/// properties (getters, fields, or setters) other than the standard `state`.
///
/// All state should be consolidated into the `state` property using a dedicated
/// model class, rather than exposing multiple public properties on the notifier.
class AvoidPublicNotifierProperties extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_public_notifier_properties',
    'Avoid public properties on Notifier classes.',
    correctionMessage:
        'Consolidate state into the state property using a model class, '
        'or make this property private.',
  );

  AvoidPublicNotifierProperties()
    : super(
        name: 'avoid_public_notifier_properties',
        description:
            'Warns when a Notifier or AsyncNotifier subclass declares '
            'public properties other than the standard state property.',
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
  final AvoidPublicNotifierProperties rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !notifierChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is FieldDeclaration) {
        _checkFieldDeclaration(member);
      } else if (member is MethodDeclaration) {
        _checkMethodDeclaration(member);
      }
    }
  }

  void _checkFieldDeclaration(FieldDeclaration member) {
    if (member.isStatic) return;

    for (final variable in member.fields.variables) {
      final name = variable.name.lexeme;
      if (name.startsWith('_')) continue;
      rule.reportAtToken(variable.name);
    }
  }

  void _checkMethodDeclaration(MethodDeclaration member) {
    if (!member.isGetter && !member.isSetter) return;
    if (member.isStatic) return;

    final name = member.name.lexeme;
    if (name.startsWith('_')) return;
    if (name == 'state') return;

    // Skip @override members (inherited from base class)
    if (_hasOverrideAnnotation(member)) return;

    rule.reportAtToken(member.name);
  }

  static bool _hasOverrideAnnotation(MethodDeclaration node) {
    for (final annotation in node.metadata) {
      if (annotation.name.name == 'override') return true;
    }
    return false;
  }
}
