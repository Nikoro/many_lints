import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../primary_constructor_candidate.dart';

class PreferPrimaryConstructors extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_primary_constructors',
    "'{0}' can declare its constructor in the type header.",
    correctionMessage:
        "Move the constructor of '{0}' into the type header as a primary "
        'constructor.',
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
