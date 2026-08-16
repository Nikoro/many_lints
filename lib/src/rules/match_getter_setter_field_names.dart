import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a getter and setter pair does not read and write the same field.
///
/// ```dart
/// int get width => _width;
/// set width(int value) => _height = value;   // writes the wrong field
/// ```
///
/// This is the copy-paste bug that type checking cannot catch: both members
/// compile, both have the right signature, and the mismatch only shows up as a
/// value that will not stick. It is most common where a class has several
/// similar pairs, which is exactly where it is hardest to spot by reading.
///
/// Only a pair whose bodies are a single field reference is considered — a
/// getter that computes, or a setter that validates before assigning, has no
/// single field to compare and is skipped rather than guessed at.
class MatchGetterSetterFieldNames extends ManyLintsRule {
  static const LintCode code = LintCode(
    'match_getter_setter_field_names',
    "The getter for '{0}' reads '{1}' but its setter writes '{2}'.",
    correctionMessage:
        'Make both use the same field, or rename the pair if they are meant '
        'to be different.',
  );

  MatchGetterSetterFieldNames()
    : super(
        name: 'match_getter_setter_field_names',
        description:
            'Warns when a getter and setter pair does not use the same '
            'backing field.',
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
    registry.addMixinDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MatchGetterSetterFieldNames rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) => _check(node.body);

  @override
  void visitMixinDeclaration(MixinDeclaration node) => _check(node.body);

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) =>
      _check(node.body);

  void _check(AstNode body) {
    if (body is! BlockClassBody) return;

    final methods = body.members.whereType<MethodDeclaration>();
    final getters = <String, MethodDeclaration>{};
    final setters = <String, MethodDeclaration>{};

    for (final method in methods) {
      if (method.isGetter) getters[method.name.lexeme] = method;
      if (method.isSetter) setters[method.name.lexeme] = method;
    }

    for (final MapEntry(key: name, value: getter) in getters.entries) {
      final setter = setters[name];
      if (setter == null) continue;

      final read = _fieldRead(getter);
      final written = _fieldWritten(setter);
      if (read == null || written == null) continue;
      if (read == written) continue;

      rule.reportAtToken(setter.name, arguments: [name, read, written]);
    }
  }

  /// The single field a getter returns, or `null` when it computes anything.
  String? _fieldRead(MethodDeclaration getter) {
    final expression = switch (getter.body) {
      ExpressionFunctionBody(:final expression) => expression,
      BlockFunctionBody(
        block: Block(statements: [ReturnStatement(:final expression?)]),
      ) =>
        expression,
      _ => null,
    };

    return _fieldName(expression);
  }

  /// The single field a setter assigns, or `null` when it does anything else.
  String? _fieldWritten(MethodDeclaration setter) {
    final expression = switch (setter.body) {
      ExpressionFunctionBody(:final expression) => expression,
      BlockFunctionBody(
        block: Block(statements: [ExpressionStatement(:final expression)]),
      ) =>
        expression,
      _ => null,
    };

    if (expression is! AssignmentExpression) return null;
    // Only a plain `=` compares meaningfully: `??=` and `+=` read the field
    // too, and their asymmetry with the getter can be deliberate.
    if (expression.operator.lexeme != '=') return null;

    return _fieldName(expression.leftHandSide);
  }

  /// The name of a bare or `this.`-qualified field reference.
  String? _fieldName(Expression? expression) => switch (expression) {
    SimpleIdentifier(:final name) => name,
    PrefixedIdentifier(
      prefix: SimpleIdentifier(name: 'this'),
      :final identifier,
    ) =>
      identifier.name,
    PropertyAccess(target: ThisExpression(), :final propertyName) =>
      propertyName.name,
    _ => null,
  };
}
