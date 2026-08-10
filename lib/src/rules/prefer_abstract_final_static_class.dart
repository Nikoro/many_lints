import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a class containing only static members is not marked as
/// `abstract final`, which would prevent instantiation and inheritance.
class PreferAbstractFinalStaticClass extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_abstract_final_static_class',
    'Classes with only static members should be declared as abstract final.',
    correctionMessage:
        "Add 'abstract final' modifiers to prevent "
        'instantiation and inheritance.',
  );

  PreferAbstractFinalStaticClass()
    : super(
        name: 'prefer_abstract_final_static_class',
        description:
            'Warns when a class with only static members is not abstract final.',
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
  final PreferAbstractFinalStaticClass rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Skip if already abstract final
    if (node.abstractKeyword != null && node.finalKeyword != null) return;

    // Skip classes with other modifiers that make abstract final inappropriate
    if (node.sealedKeyword != null ||
        node.baseKeyword != null ||
        node.interfaceKeyword != null ||
        node.mixinKeyword != null) {
      return;
    }

    final body = node.body;
    if (body is! BlockClassBody) return;

    final members = body.members;

    // Skip empty classes
    if (members.isEmpty) return;

    var hasStaticMember = false;

    // Check that all members are static
    for (final member in members) {
      switch (member) {
        case ConstructorDeclaration():
          // A trivial private constructor is the older idiom for the very
          // thing this rule suggests — guarding against instantiation. It is
          // made redundant by `abstract final`, so allow it (and let the fix
          // delete it). Any other constructor means the class is meant to be
          // instantiated.
          if (!_isInstantiationGuard(member)) return;
        case MethodDeclaration(:final isStatic):
          if (!isStatic) return;
          hasStaticMember = true;
        case FieldDeclaration(:final isStatic):
          if (!isStatic) return;
          hasStaticMember = true;
        default:
          // Unknown member type — be conservative
          return;
      }
    }

    // A class holding nothing but a private constructor is not a static
    // holder; leave it alone.
    if (!hasStaticMember) return;

    rule.reportAtNode(node);
  }

  /// Whether [node] is an empty, parameterless private constructor whose only
  /// purpose is to prevent instantiation, e.g. `MyConstants._();`.
  ///
  /// Anything richer — parameters, initializers, a redirection or a body — is
  /// doing real work that `abstract final` would not preserve.
  static bool _isInstantiationGuard(ConstructorDeclaration node) {
    if (node.name?.lexeme.startsWith('_') != true) return false;
    if (node.factoryKeyword != null) return false;
    if (node.constKeyword != null) return false;
    if (node.parameters.parameters.isNotEmpty) return false;
    if (node.initializers.isNotEmpty) return false;
    if (node.redirectedConstructor != null) return false;

    return switch (node.body) {
      EmptyFunctionBody() => true,
      BlockFunctionBody(:final block) => block.statements.isEmpty,
      _ => false,
    };
  }
}
