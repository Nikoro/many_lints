import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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
    if (node.abstractKeyword != null && node.finalKeyword != null) return;
    if (_hasConflictingModifier(node)) return;
    if (_hasInstantiablePrimaryConstructor(node)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    final members = body.members;
    if (members.isEmpty) return;

    var hasStaticMember = false;

    for (final member in members) {
      switch (member) {
        case ConstructorDeclaration():
          if (!_isInstantiationGuard(member)) return;
        case MethodDeclaration(:final isStatic):
          if (!isStatic) return;
          hasStaticMember = true;
        case FieldDeclaration(:final isStatic):
          if (!isStatic) return;
          hasStaticMember = true;
        default:
          return;
      }
    }

    if (!hasStaticMember) return;

    rule.reportAtNode(node);
  }

  static bool _hasConflictingModifier(ClassDeclaration node) =>
      node.sealedKeyword != null ||
      node.baseKeyword != null ||
      node.interfaceKeyword != null ||
      node.mixinKeyword != null;

  static bool _hasInstantiablePrimaryConstructor(ClassDeclaration node) =>
      switch (node.namePart) {
        PrimaryConstructorDeclaration(
          :final formalParameters,
          :final constructorName,
        ) =>
          formalParameters.parameters.isNotEmpty ||
              !(constructorName?.name.lexeme.startsWith('_') ?? false),
        _ => false,
      };

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
