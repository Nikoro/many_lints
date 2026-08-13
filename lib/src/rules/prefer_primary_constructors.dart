import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a class consists only of final fields and a constructor that
/// does nothing but assign them, so it can collapse into a Dart 3.13 primary
/// constructor.
///
/// **Bad:**
/// ```dart
/// class Point {
///   final int x;
///   final int y;
///   Point(this.x, this.y);
/// }
/// ```
///
/// **Good:**
/// ```dart
/// class Point(final int x, final int y);
/// ```
///
/// Only classes whose *entire* body is those fields plus the one constructor
/// are reported, because only those collapse to the `;` form without leaving
/// anything behind. A class holding a method, a getter, a static member or a
/// second constructor keeps its body under a primary constructor, which is a
/// larger and more debatable edit — see the `_Visitor.visitClassDeclaration`
/// comment for why that stayed out of v1.
///
/// This does not overlap with the SDK's `use_declaring_parameters`: that rule
/// visits `PrimaryConstructorDeclaration` nodes only, so it never fires on a
/// class that has yet to adopt one. It polishes classes that already migrated;
/// this rule is what suggests migrating.
class PreferPrimaryConstructors extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_primary_constructors',
    "Class '{0}' can be declared with a primary constructor.",
    correctionMessage:
        'Move the fields into the class header, e.g. '
        'class {0}(final int x);',
  );

  PreferPrimaryConstructors()
    : super(
        name: 'prefer_primary_constructors',
        description:
            'Warns when a class of final fields plus a field-assigning '
            'constructor could use a primary constructor (Dart 3.13+).',
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
  final PreferPrimaryConstructors rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final unit = node.thisOrAncestorOfType<CompilationUnit>();
    if (unit == null ||
        !unit.featureSet.isEnabled(Feature.primary_constructors)) {
      return;
    }

    // Already migrated: the name part is a primary constructor, not a plain
    // name. The SDK's `use_declaring_parameters` owns this case.
    if (node.namePart is PrimaryConstructorDeclaration) return;

    // A primary constructor is a *generative* constructor for the class, so
    // the class must not already extend something whose construction it would
    // have to forward to, and must not be abstract/sealed (which cannot be
    // constructed directly in the way this rewrite implies).
    if (node.abstractKeyword != null || node.sealedKeyword != null) return;
    if (node.extendsClause != null || node.withClause != null) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    ConstructorDeclaration? constructor;
    final fields = <VariableDeclaration>[];

    for (final member in body.members) {
      switch (member) {
        case ConstructorDeclaration():
          // A second constructor would have to redirect to the primary one --
          // out of scope for v1.
          if (constructor != null) return;
          constructor = member;
        case FieldDeclaration():
          // A static field is unrelated to construction but still has to live
          // in a body, which the `;` form does not have.
          if (member.isStatic) return;
          final list = member.fields;
          // Only `final` fields can become declaring parameters here; a
          // mutable field would silently change meaning.
          if (!list.isFinal) return;
          for (final field in list.variables) {
            // An initialized field is not assigned by the constructor, so it
            // is not a parameter -- and it cannot survive the `;` form.
            if (field.initializer != null) return;
            fields.add(field);
          }
        case _:
          // Any method, getter, setter or nested declaration needs a body.
          return;
      }
    }

    if (constructor == null || fields.isEmpty) return;

    // The constructor must be the unnamed generative one, with no factory
    // redirection and nothing but `this.x` parameters.
    if (constructor.factoryKeyword != null) return;
    if (constructor.externalKeyword != null) return;
    if (constructor.redirectedConstructor != null) return;
    if (constructor.name != null) return;

    // An initializer list or a real body does work beyond assigning fields.
    // The rule stays silent rather than reporting something the fix would
    // have to decline, which would leave an unactionable diagnostic.
    if (constructor.initializers.isNotEmpty) return;
    final constructorBody = constructor.body;
    if (constructorBody is! EmptyFunctionBody) return;

    final parameters = constructor.parameters.parameters;
    if (parameters.isEmpty) return;

    // Every parameter must be an initializing formal (`this.x`) naming a field
    // declared in this class, and every field must be covered. Anything else
    // -- a plain parameter, a super formal -- means the rewrite is not a pure
    // relocation of the field list.
    final fieldNames = fields.map((f) => f.name.lexeme).toSet();
    final covered = <String>{};

    for (final parameter in parameters) {
      // `this.x` is its own node type -- a `FieldFormalParameter`, not a
      // `RegularFormalParameter` carrying a `this` token. A plain `int x` or a
      // `super.x` therefore fails this test, which is exactly what we want.
      if (parameter is! FieldFormalParameter) return;
      // A function-typed initializing formal (`this.cb(int)`) has no primary
      // constructor spelling.
      if (parameter.functionTypedSuffix != null) return;

      final name = parameter.name.lexeme;
      if (!fieldNames.contains(name)) return;
      // A duplicate would mean the source did not compile; treat defensively.
      if (!covered.add(name)) return;
    }

    if (covered.length != fieldNames.length) return;

    rule.reportAtToken(
      node.namePart.typeName,
      arguments: [node.namePart.typeName.lexeme],
    );
  }
}
