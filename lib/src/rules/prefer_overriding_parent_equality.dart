import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a class extends a parent that overrides `==` and `hashCode`
/// but does not override them itself, which can lead to incorrect equality
/// comparisons.
class PreferOverridingParentEquality extends AnalysisRule {
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
  void registerNodeProcessors(
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
    // Skip abstract classes — they can't be instantiated
    if (node.abstractKeyword != null) return;

    final element = node.declaredFragment?.element;
    if (element == null) return;

    // Check if any ancestor defines custom == and hashCode
    if (!_anyAncestorOverridesEquality(element)) return;

    // Check what the child overrides (via AST)
    final childOverridesEquals = _astOverridesEquals(node);
    final childOverridesHashCode = _astOverridesHashCode(node);

    // Warn if missing either
    if (!childOverridesEquals || !childOverridesHashCode) {
      rule.reportAtToken(node.namePart.typeName);
    }
  }

  static bool _anyAncestorOverridesEquality(ClassElement element) {
    for (final supertype in element.allSupertypes) {
      // Skip Object — it defines == and hashCode but they're the defaults
      if (supertype.element.name == 'Object') continue;

      if (_typeOverridesEquals(supertype) &&
          _typeOverridesHashCode(supertype)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if the interface type declares a non-abstract `==` operator.
  static bool _typeOverridesEquals(InterfaceType type) {
    for (final method in type.methods) {
      if (method.name == '==' && !method.isAbstract) return true;
    }
    return false;
  }

  /// Checks if the interface type declares a non-abstract `hashCode` getter.
  static bool _typeOverridesHashCode(InterfaceType type) {
    for (final getter in type.getters) {
      if (getter.name == 'hashCode' && !getter.isAbstract) return true;
    }
    return false;
  }

  /// Checks if the class AST declares an `==` operator.
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

  /// Checks if the class AST declares a `hashCode` getter.
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
