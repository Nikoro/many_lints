import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a class containing only static members is not marked as
/// `abstract final`, which would prevent instantiation and inheritance.
class PreferAbstractFinalStaticClass extends AnalysisRule {
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
  void registerNodeProcessors(
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

    // Check that all members are static
    for (final member in members) {
      switch (member) {
        case ConstructorDeclaration():
          // Any constructor means this isn't a purely static class
          return;
        case MethodDeclaration(:final isStatic):
          if (!isStatic) return;
        case FieldDeclaration(:final isStatic):
          if (!isStatic) return;
        default:
          // Unknown member type — be conservative
          return;
      }
    }

    rule.reportAtNode(node);
  }
}
