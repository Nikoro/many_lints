import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when one class reads another class's private member.
///
/// Dart scopes privacy to the **library**, not the class, so `_field` is
/// visible to every declaration in the same file — and to every `part` of it.
/// Most people write `_` meaning "mine", and the language quietly means
/// "this file's". In a long file or a `part`-heavy library those are very
/// different things, and this rule makes the language behave the way the
/// underscore already reads.
///
/// The exemptions are what keep it usable, because several idioms legitimately
/// reach across:
///
/// - A `State` reading `widget._foo`, which is one object split in two by the
///   framework.
/// - `copyWith`, `operator ==` and `hashCode`, which exist precisely to read
///   another instance's fields.
/// - Another instance of the **same** class: `other._value` inside `==` is the
///   pattern, not a violation.
/// - Generated code, which is expected to reach into what it generated.
class AvoidAccessingOtherClassesPrivateMembers extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_accessing_other_classes_private_members',
    "The private member '{0}' belongs to another class.",
    correctionMessage:
        'Expose it deliberately, or move the code that needs it.',
  );

  AvoidAccessingOtherClassesPrivateMembers()
    : super(
        name: 'avoid_accessing_other_classes_private_members',
        description:
            "Warns when one class reads another class's private member.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPropertyAccess(this, visitor);
    registry.addPrefixedIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// Members whose whole job is to read another instance's fields.
  static const _defaultIgnoredMembers = {
    'copyWith',
    '==',
    'hashCode',
    'toString',
  };

  final AvoidAccessingOtherClassesPrivateMembers rule;

  _Visitor(this.rule);

  @override
  void visitPropertyAccess(PropertyAccess node) =>
      _check(node, node.propertyName, node.realTarget);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) =>
      _check(node, node.identifier, node.prefix);

  void _check(AstNode node, SimpleIdentifier property, Expression? target) {
    final name = property.name;
    if (!name.startsWith('_')) return;
    if (target == null) return;

    // `this._x` and a bare `_x` are the class's own business.
    if (target is ThisExpression) return;

    final enclosing = node
        .thisOrAncestorOfType<ClassDeclaration>()
        ?.declaredFragment
        ?.element;
    if (enclosing == null) return;

    final ignored = rule.config.nameSetOption(
      'ignored_members',
      defaultValue: _defaultIgnoredMembers,
    );
    final member = node.thisOrAncestorOfType<MethodDeclaration>();
    if (member != null && ignored.contains(member.name.lexeme)) return;

    // A `State` reading `widget._foo` is one object the framework split in two.
    if (target is SimpleIdentifier && target.name == 'widget') return;

    final owner = _ownerOf(target);
    if (owner == null) return;
    // Another instance of the SAME class is the `==`/`copyWith` pattern.
    if (owner == enclosing) return;

    rule.reportAtNode(property, arguments: [name]);
  }

  /// The class a target expression's static type belongs to.
  InterfaceElement? _ownerOf(Expression target) {
    final type = target.staticType;
    final element = type?.element;

    return element is InterfaceElement ? element : null;
  }
}
