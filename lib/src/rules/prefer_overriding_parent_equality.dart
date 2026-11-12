import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../test_double_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

class PreferOverridingParentEquality extends ManyLintsRule {
  static const Map<String, TypeChecker> defaultIgnoredTypes = {
    'Widget': widgetChecker,
    'Mock': mockChecker,
    'Fake': fakeChecker,
  };

  static const LintCode code = LintCode(
    'prefer_overriding_parent_equality',
    'Parent class overrides == and hashCode but this class does not.',
    correctionMessage:
        'Override both == and hashCode to account for this class\'s fields.',
  );

  PreferOverridingParentEquality()
    : super(
        name: 'prefer_overriding_parent_equality',
        description:
            'Warns when a child class does not override == and hashCode '
            'that its parent overrides.',
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
  final PreferOverridingParentEquality rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.abstractKeyword != null) return;

    final element = node.declaredFragment?.element;
    if (element == null) return;

    if (_isIgnoredType(element)) return;

    if (!_anyAncestorOverridesEquality(element)) return;

    final childOverridesEquals = _astOverridesEquals(node);
    final childOverridesHashCode = _astOverridesHashCode(node);

    if (!childOverridesEquals || !childOverridesHashCode) {
      rule.reportAtToken(node.namePart.typeName);
    }
  }

  bool _isIgnoredType(ClassElement element) {
    final ignored = rule.config.nameSetOption(
      'ignored_types',
      defaultValue: PreferOverridingParentEquality.defaultIgnoredTypes.keys
          .toSet(),
    );

    for (final name in ignored) {
      final pinnedDefaultChecker =
          PreferOverridingParentEquality.defaultIgnoredTypes[name];
      final checker = pinnedDefaultChecker ?? TypeChecker.fromName(name);
      if (checker.isSuperOf(element)) return true;
    }

    return false;
  }

  static bool _anyAncestorOverridesEquality(ClassElement element) {
    for (final supertype in element.allSupertypes) {
      final hasDefaultEquality = supertype.element.name == 'Object';
      if (hasDefaultEquality) continue;

      if (_typeOverridesEquals(supertype) &&
          _typeOverridesHashCode(supertype)) {
        return true;
      }
    }
    return false;
  }

  static bool _typeOverridesEquals(InterfaceType type) {
    for (final method in type.methods) {
      if (method.name == '==' && !method.isAbstract) return true;
    }
    return false;
  }

  static bool _typeOverridesHashCode(InterfaceType type) {
    for (final getter in type.getters) {
      if (getter.name == 'hashCode' && !getter.isAbstract) return true;
    }
    return false;
  }

  static bool _astOverridesEquals(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return false;

    for (final member in body.members) {
      if (member is MethodDeclaration &&
          member.isOperator &&
          member.name.lexeme == '==') {
        return true;
      }
    }
    return false;
  }

  static bool _astOverridesHashCode(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return false;

    for (final member in body.members) {
      if (member is MethodDeclaration &&
          member.isGetter &&
          member.name.lexeme == 'hashCode') {
        return true;
      }
    }
    return false;
  }
}
