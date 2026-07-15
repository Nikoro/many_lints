import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a constructor declares a public named parameter whose only
/// purpose is to initialize a private field with the same name.
///
/// Since Dart 3.12 a named initializing formal can be private directly
/// (`Foo({required this._name})`); callers still pass the public name
/// (`Foo(name: ...)`), so the initializer-list boilerplate is unnecessary.
///
/// **Bad:**
/// ```dart
/// class Bird {
///   final String _petName;
///   Bird({required String petName}) : _petName = petName;
/// }
/// ```
///
/// **Good:**
/// ```dart
/// class Bird {
///   final String _petName;
///   Bird({required this._petName});
/// }
/// ```
class PreferPrivateNamedParameters extends AnalysisRule {
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
  void registerNodeProcessors(
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
      // Only `_name` -> `name` (single leading underscore, non-private rest).
      if (!fieldName.startsWith('_')) continue;
      final publicName = fieldName.substring(1);
      if (publicName.isEmpty || publicName.startsWith('_')) continue;

      final value = initializer.expression;
      if (value is! SimpleIdentifier || value.name != publicName) continue;

      final parameter = _findNamedParameter(node, publicName);
      if (parameter == null) continue;

      // The declared parameter type must match the field type exactly,
      // otherwise `this._name` would change the parameter's type.
      if (!_typeMatchesField(parameter, initializer)) continue;

      // The parameter must not be referenced anywhere else in the
      // constructor (other initializers, asserts, body, default values).
      if (_countParameterReferences(node, parameter) != 1) continue;

      rule.reportAtNode(parameter, arguments: [fieldName]);
    }
  }

  /// Finds a plain named parameter with the given [name], or `null` if it
  /// doesn't exist or is already an initializing/super formal.
  static FormalParameter? _findNamedParameter(
    ConstructorDeclaration node,
    String name,
  ) {
    for (final parameter in node.parameters.parameters) {
      if (parameter.name?.lexeme != name) continue;
      if (!parameter.isNamed) return null;
      if (parameter is! RegularFormalParameter) return null;
      // Converting a function-typed parameter would lose its signature.
      if (parameter.functionTypedSuffix != null) return null;
      return parameter;
    }
    return null;
  }

  /// Whether the parameter's declared type is the same as the initialized
  /// field's type (an untyped parameter always matches).
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

  /// Counts identifier references to [parameter] within the constructor.
  static int _countParameterReferences(
    ConstructorDeclaration node,
    FormalParameter parameter,
  ) {
    final element = parameter.declaredFragment?.element;
    if (element == null) return 2; // Unresolved - be conservative.

    final counter = _ReferenceCounter(element);
    node.accept(counter);
    return counter.count;
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
