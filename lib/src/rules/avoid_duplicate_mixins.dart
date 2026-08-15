import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when the same mixin is applied twice in one `with` clause.
///
/// `class A with M, M {}` compiles, and the second application contributes
/// nothing — the members are already there. It reads as though two different
/// behaviours are being mixed in, which is what makes it worth reporting
/// rather than harmless: a reader counting mixins sees one more than exists.
///
/// Duplicates arrive through merges and through a rename that collapses two
/// once-distinct names onto one.
class AvoidDuplicateMixins extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_mixins',
    "The mixin '{0}' is applied more than once.",
    correctionMessage: 'Remove the repeated mixin.',
  );

  AvoidDuplicateMixins()
    : super(
        name: 'avoid_duplicate_mixins',
        description:
            'Warns when a `with` clause lists the same mixin more than once, '
            'where every application after the first adds nothing.',
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
    registry.addClassTypeAlias(this, visitor);
    registry.addEnumDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidDuplicateMixins rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) => _check(node.withClause);

  @override
  void visitClassTypeAlias(ClassTypeAlias node) => _check(node.withClause);

  @override
  void visitEnumDeclaration(EnumDeclaration node) => _check(node.withClause);

  void _check(WithClause? clause) {
    if (clause == null) return;

    final seen = <String>{};
    for (final mixin in clause.mixinTypes) {
      final key = _mixinKey(mixin);

      if (!seen.add(key)) {
        rule.reportAtNode(mixin, arguments: [mixin.toSource()]);
      }
    }
  }

  /// Identifies a mixin application, so that only genuinely identical ones
  /// collide.
  ///
  /// The resolved type is used rather than the source text, so an aliased
  /// import (`M` and `alias.M`) counts as one mixin. It also keeps the type
  /// arguments, because `M<int>` and `M<String>` share an element but bring in
  /// different members — applying both is legitimate, not a duplicate.
  String _mixinKey(NamedType mixin) {
    final type = mixin.type;
    return type == null ? mixin.toSource() : type.getDisplayString();
  }
}
