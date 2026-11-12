import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

class PreferEquatableMixin extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_equatable_mixin',
    "Prefer 'with {0}' to extending Equatable.",
    correctionMessage: "Replace 'extends Equatable' with 'with {0}'.",
  );

  PreferEquatableMixin()
    : super(
        name: 'prefer_equatable_mixin',
        description:
            'Warns when a class extends Equatable instead of mixing it in.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferEquatableMixin rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  static const _equatableChecker = TypeChecker.fromName(
    'Equatable',
    packageName: 'equatable',
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return;

    final superclass = extendsClause.superclass;
    final element = superclass.element;
    if (element == null) return;

    if (element is! ClassElement || !_equatableChecker.isExactly(element)) {
      return;
    }
    final library = context.libraryElement;
    if (library == null) return;
    final mixin = equatableMixinName(element, library);
    if (mixin == null) return;

    rule.reportAtNode(extendsClause, arguments: [mixin]);
  }
}

String? equatableMixinName(ClassElement equatable, LibraryElement library) {
  if (equatable.isMixinClass) return 'Equatable';
  for (final fragment in library.fragments) {
    for (final import in fragment.libraryImports) {
      final namespace = import.importedLibrary?.exportNamespace;
      if (namespace == null || namespace.get2('Equatable') != equatable) {
        continue;
      }
      if (namespace.get2('EquatableMixin') is MixinElement) {
        return 'EquatableMixin';
      }
    }
  }
  return null;
}
