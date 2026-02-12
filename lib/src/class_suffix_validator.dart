import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'type_checker.dart';

/// Base class for rules that validate class name suffixes based on supertype.
///
/// This class provides a reusable pattern for enforcing naming conventions where
/// classes extending/implementing a specific type should have a corresponding
/// suffix in their name (e.g., classes extending `Bloc` should end with `Bloc`).
///
/// Subclasses only need to provide the rule configuration via constructor.
abstract class ClassSuffixValidator extends AnalysisRule {
  final String requiredSuffix;
  final TypeChecker typeChecker;
  final LintCode _lintCode;

  /// Creates a class suffix validator rule.
  ///
  /// [name]: The lint rule name (e.g., 'use_bloc_suffix')
  /// [description]: Brief description of the rule
  /// [requiredSuffix]: The suffix that should appear in class names (e.g., 'Bloc')
  /// [baseClassName]: The name of the base class/interface to check for (e.g., 'Bloc')
  /// [packageName]: The package defining the base class (e.g., 'bloc')
  ClassSuffixValidator({
    required super.name,
    required super.description,
    required this.requiredSuffix,
    required String baseClassName,
    required String packageName,
  }) : typeChecker = TypeChecker.fromName(
         baseClassName,
         packageName: packageName,
       ),
       _lintCode = LintCode(
         name,
         'Use $requiredSuffix suffix',
         correctionMessage: 'Ex. {0}$requiredSuffix',
       );

  @override
  LintCode get diagnosticCode => _lintCode;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _ClassSuffixVisitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _ClassSuffixVisitor extends SimpleAstVisitor<void> {
  final ClassSuffixValidator rule;

  _ClassSuffixVisitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    final name = node.namePart.typeName;
    final className = name.lexeme;

    // Check if class extends/implements the target type and lacks the suffix
    if (rule.typeChecker.isSuperOf(element) &&
        !className.endsWith(rule.requiredSuffix)) {
      rule.reportAtToken(name, arguments: [className]);
    }
  }
}
