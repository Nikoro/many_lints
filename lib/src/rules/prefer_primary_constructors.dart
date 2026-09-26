import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../primary_constructor_candidate.dart';

/// Warns when a class or enum declares a generative constructor that can
/// move into the type header as a Dart 3.13 primary constructor.
///
/// **Bad:**
/// ```dart
/// class Point {
///   final int x;
///   final int y;
///   Point(this.x, this.y);
///
///   double get length => sqrt(x * x + y * y);
/// }
/// ```
///
/// **Good:**
/// ```dart
/// class Point(final int x, final int y) {
///   double get length => sqrt(x * x + y * y);
/// }
/// ```
///
/// Stricter than the SDK's `use_primary_constructors` where it matters and
/// quieter where it does not: a type that declares no constructor is never
/// reported, because converting it only adds an empty `()` to the header.
/// What counts as convertible lives in [PrimaryConstructorCandidate], shared
/// with the fix, so every report comes with a working rewrite.
class PreferPrimaryConstructors extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_primary_constructors',
    "'{0}' can declare its constructor in the type header.",
    correctionMessage:
        'Move it into the header as a primary constructor, for example '
        '{0}(final int x).',
  );

  PreferPrimaryConstructors()
    : super(
        name: 'prefer_primary_constructors',
        description:
            'Warns when a class or enum constructor could move into the '
            'type header as a primary constructor (Dart 3.13+).',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry
      ..addClassDeclaration(this, visitor)
      ..addEnumDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferPrimaryConstructors rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) => _check(node);

  @override
  void visitEnumDeclaration(EnumDeclaration node) => _check(node);

  void _check(CompilationUnitMember node) {
    final candidate = PrimaryConstructorCandidate.tryRead(node);
    if (candidate == null) return;
    final name = candidate.namePart.typeName;
    rule.reportAtToken(name, arguments: [name.lexeme]);
  }
}
