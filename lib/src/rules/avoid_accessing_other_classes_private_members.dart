import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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

    // Edge case: a State reading widget._foo is one object the framework split in two
    if (target is SimpleIdentifier && target.name == 'widget') return;

    final owner = _ownerOf(target);
    if (owner == null) return;
    // Edge case: another instance of the same class is the == and copyWith pattern
    if (owner == enclosing) return;

    rule.reportAtNode(property, arguments: [name]);
  }

  InterfaceElement? _ownerOf(Expression target) {
    final type = target.staticType;
    final element = type?.element;

    return element is InterfaceElement ? element : null;
  }
}
