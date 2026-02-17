import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a generic type parameter shadows a top-level type declaration
/// in the same file (class, mixin, enum, typedef, or extension type).
///
/// Shadowing can be confusing when a parameter or variable annotated with the
/// generic looks like it refers to the real class.
class AvoidGenericsShadowing extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_generics_shadowing',
    "The type parameter '{0}' shadows the top-level declaration '{0}'.",
    correctionMessage:
        'Try renaming the type parameter to a single letter like T, R, or E.',
  );

  AvoidGenericsShadowing()
    : super(
        name: 'avoid_generics_shadowing',
        description:
            'Warns when a generic type parameter shadows a top-level '
            'declaration in the same file.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidGenericsShadowing rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // Collect all top-level type names in this file.
    final topLevelNames = <String>{};
    for (final declaration in node.declarations) {
      switch (declaration) {
        case ClassDeclaration(:final namePart):
          topLevelNames.add(namePart.typeName.lexeme);
        case MixinDeclaration(:final name):
          topLevelNames.add(name.lexeme);
        case EnumDeclaration(:final namePart):
          topLevelNames.add(namePart.typeName.lexeme);
        case GenericTypeAlias(:final name):
          topLevelNames.add(name.lexeme);
        case FunctionTypeAlias(:final name):
          topLevelNames.add(name.lexeme);
        case ExtensionTypeDeclaration(:final primaryConstructor):
          topLevelNames.add(primaryConstructor.typeName.lexeme);
        default:
          break;
      }
    }

    if (topLevelNames.isEmpty) return;

    // Check all type parameter lists in the file.
    final checker = _TypeParameterChecker(rule, topLevelNames);
    node.visitChildren(checker);
  }
}

/// Recursively visits the AST to find type parameter lists and check for
/// shadowing.
class _TypeParameterChecker extends RecursiveAstVisitor<void> {
  final AvoidGenericsShadowing rule;
  final Set<String> topLevelNames;

  _TypeParameterChecker(this.rule, this.topLevelNames);

  @override
  void visitTypeParameter(TypeParameter node) {
    final name = node.name.lexeme;
    if (topLevelNames.contains(name)) {
      rule.reportAtToken(node.name, arguments: [name]);
    }
    super.visitTypeParameter(node);
  }
}
