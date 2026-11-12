import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when a class directly extends `Equatable` instead of mixing it in.
/// Mixing it in preserves the ability to extend another base class while
/// keeping all equatable features.
///
/// The mixin is named after the resolved `package:equatable`: equatable 2.1
/// and later declare `Equatable` as a mixin class (3.0 removed the deprecated
/// `EquatableMixin`), and 2.0 only has `EquatableMixin`.
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

/// The name to mix in instead of extending [equatable], as [library] sees
/// package:equatable, or `null` when that version offers neither.
///
/// `Equatable` itself when it is a mixin class (equatable 2.1 and later,
/// where `EquatableMixin` is deprecated, and 3.0, where it is gone), else
/// `EquatableMixin` when an import of [equatable] also exports it (2.0).
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
