import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferPrivateNamedParameters extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_private_named_parameters',
    'Named parameter is only used to initialize the private field {0}.',
    correctionMessage: 'Use a private named parameter (this.{0}) instead.',
  );

  PreferPrivateNamedParameters()
    : super(
        name: 'prefer_private_named_parameters',
        description:
            'Warns when a public named parameter only initializes a private '
            'field and could be a private named parameter (Dart 3.12+).',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferPrivateNamedParameters rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final unit = node.thisOrAncestorOfType<CompilationUnit>();
    if (unit == null ||
        !unit.featureSet.isEnabled(Feature.private_named_parameters)) {
      return;
    }

    for (final initializer in node.initializers) {
      if (initializer is! ConstructorFieldInitializer) continue;

      final fieldName = initializer.fieldName.name;
      final publicName = _publicNameOf(fieldName);
      if (publicName == null) continue;

      final value = initializer.expression;
      if (value is! SimpleIdentifier) continue;

      final onlySameName = rule.config.boolOption(
        'only_same_name',
        defaultValue: true,
      );
      if (onlySameName && value.name != publicName) continue;

      final parameter = _findNamedParameter(node, value.name);
      if (parameter == null) continue;
      if (!_typeMatchesField(parameter, initializer)) continue;
      if (!_isReferencedOnce(node, parameter)) continue;

      rule.reportAtNode(parameter, arguments: [fieldName]);
    }
  }

  static String? _publicNameOf(String fieldName) {
    if (!fieldName.startsWith('_')) return null;
    final publicName = fieldName.substring(1);
    if (publicName.isEmpty || publicName.startsWith('_')) return null;
    return publicName;
  }

  static FormalParameter? _findNamedParameter(
    ConstructorDeclaration node,
    String name,
  ) {
    for (final parameter in node.parameters.parameters) {
      if (parameter.name?.lexeme != name) continue;
      if (!parameter.isNamed) return null;
      if (parameter is! RegularFormalParameter) return null;
      if (parameter.functionTypedSuffix != null) return null;
      return parameter;
    }
    return null;
  }

  static bool _typeMatchesField(
    FormalParameter parameter,
    ConstructorFieldInitializer initializer,
  ) {
    final parameterType = parameter.type?.type;
    if (parameterType == null) return true;

    final fieldType = switch (initializer.fieldName.element) {
      PropertyInducingElement(:final type) => type,
      _ => null,
    };
    return fieldType != null && parameterType == fieldType;
  }

  static bool _isReferencedOnce(
    ConstructorDeclaration node,
    FormalParameter parameter,
  ) {
    final element = parameter.declaredFragment?.element;
    if (element == null) return false;

    final counter = _ReferenceCounter(element);
    node.accept(counter);
    return counter.count == 1;
  }
}

class _ReferenceCounter extends RecursiveAstVisitor<void> {
  final Object element;
  int count = 0;

  _ReferenceCounter(this.element);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == element) count++;
    super.visitSimpleIdentifier(node);
  }
}
