import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';

class AvoidPublicNotifierProperties extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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
      if (name == 'state') continue;

      if (variable.isFinal || variable.isConst) continue;

      final element = variable.declaredFragment?.element;
      if (!_isVisibleOutsideTheNotifier(element)) continue;

      rule.reportAtToken(variable.name);
    }
  }

  void _checkMethodDeclaration(MethodDeclaration member) {
    if (!member.isGetter && !member.isSetter) return;
    if (member.isStatic) return;

    final name = member.name.lexeme;
    if (name.startsWith('_')) return;
    if (name == 'state') return;

    final element = member.declaredFragment?.element;
    if (!_isVisibleOutsideTheNotifier(element)) return;

    rule.reportAtToken(member.name);
  }

  static bool _isVisibleOutsideTheNotifier(Element? element) {
    if (element == null) return false;
    if (!element.isPublic) return false;

    final metadata = element.metadata;
    if (metadata.hasOverride) return false;
    if (metadata.hasProtected) return false;
    if (metadata.hasVisibleForOverriding) return false;
    if (metadata.hasVisibleForTesting) return false;

    return true;
  }
}
