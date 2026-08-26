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

/// Warns when a class extends a parent that overrides `==` and `hashCode`
/// but does not override them itself, which can lead to incorrect equality
/// comparisons.
///
/// Subtypes of a type named by `ignored_types` are skipped. Three types are
/// exempt by default, each because its identity is deliberately *not* its
/// fields:
///
/// - **`Widget`** — a widget's identity is its `runtimeType` and `key`, which
///   is what `Widget ==` compares and what the framework's element reuse
///   depends on. One comparing its fields would break `canUpdate`.
/// - **`Mock`** — a mock's identity is the instance, which is what `verify()`
///   matches on. One comparing its fields would break verification.
/// - **`Fake`** — a fake implements an interface it does not hold the data
///   for, so it inherits that interface's `==` with no fields to compare.
///
/// In each case the override this rule asks for is one the class should not
/// have, and without the exclusion the report is unavoidable: every
/// `StatelessWidget` in a Flutter project, and every mock in its test tree.
/// The only escape would be a path glob over the presentation layer and all of
/// `test/` — paths standing in for facts about types.
class PreferOverridingParentEquality extends ManyLintsRule {
  /// Types whose subtypes are exempt unless the project says otherwise.
  ///
  /// Each is pinned to its declaring package, so a project class coincidentally
  /// named `Widget`, `Mock` or `Fake` cannot silently switch the rule off for
  /// its whole subtree. That pinning matters more here than it looks: `Mock`
  /// and `Fake` are ordinary English words, and a domain class called `Fake` is
  /// far from unthinkable.
  ///
  /// Names a project adds through `ignored_types` are matched without a pin,
  /// since a type declared in the analyzed package has no `package:` URI to
  /// pin against.
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
    // Skip abstract classes — they can't be instantiated
    if (node.abstractKeyword != null) return;

    final element = node.declaredFragment?.element;
    if (element == null) return;

    if (_isIgnoredType(element)) return;

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

  /// Whether [element] is, or descends from, a type named by `ignored_types`.
  ///
  /// Matching is by supertype rather than by name, so a project's own widget
  /// base classes are covered without naming each one.
  bool _isIgnoredType(ClassElement element) {
    final ignored = rule.config.nameSetOption(
      'ignored_types',
      defaultValue: PreferOverridingParentEquality.defaultIgnoredTypes.keys
          .toSet(),
    );

    for (final name in ignored) {
      // A default type keeps its package pin; anything the project names is
      // matched bare, because it may be declared in the analyzed package and
      // have no package URI to pin against.
      final checker =
          PreferOverridingParentEquality.defaultIgnoredTypes[name] ??
          TypeChecker.fromName(name);
      if (checker.isSuperOf(element)) return true;
    }

    return false;
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
