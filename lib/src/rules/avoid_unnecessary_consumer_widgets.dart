import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';
import '../state_class_pairing.dart';

class AvoidUnnecessaryConsumerWidgets extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_consumer_widgets',
    'ConsumerWidget does not use WidgetRef. Consider using StatelessWidget instead.',
    correctionMessage: 'Change the base class and remove unused ref parameter.',
  );

  AvoidUnnecessaryConsumerWidgets()
    : super(
        name: 'avoid_unnecessary_consumer_widgets',
        description: 'Warns when ConsumerWidget does not use WidgetRef.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryConsumerWidgets rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final consumerStatefulWidgets = <ClassDeclaration>[];
    final consumerStates = <ClassDeclaration>[];
    final localMixins = <String, MixinDeclaration>{};

    for (final declaration in node.declarations) {
      if (declaration is MixinDeclaration) {
        localMixins[declaration.name.lexeme] = declaration;
        continue;
      }
      if (declaration is! ClassDeclaration) continue;

      final element = declaration.declaredFragment?.element;
      if (element == null) continue;

      if (consumerStatefulWidgetChecker.isSuperOf(element)) {
        consumerStatefulWidgets.add(declaration);
      } else if (consumerStateChecker.isSuperOf(element)) {
        consumerStates.add(declaration);
      } else {
        _checkConsumerWidget(declaration, localMixins);
      }
    }

    for (final widget in consumerStatefulWidgets) {
      final widgetName = widget.namePart.typeName.lexeme;

      final stateClass = findStateClassFor(consumerStates, widgetName);
      if (stateClass == null) continue;

      if (_isIdentifierUsed(stateClass.body, 'ref')) continue;
      if (_mixesInRefUsage(stateClass, localMixins)) continue;

      rule.reportAtToken(widget.namePart.typeName);
    }
  }

  void _checkConsumerWidget(
    ClassDeclaration cls,
    Map<String, MixinDeclaration> localMixins,
  ) {
    final superclassElement = cls.extendsClause?.superclass.element;
    if (superclassElement == null) return;

    if (!consumerWidgetChecker.isExactly(superclassElement)) return;

    final body = cls.body;
    if (body is! BlockClassBody) return;

    final buildMethod = body.members
        .whereType<MethodDeclaration>()
        .firstWhereOrNull((m) => m.name.lexeme == 'build');

    if (buildMethod == null) return;

    final refParam = buildMethod.parameters?.parameters.firstWhereOrNull(
      (p) => p is RegularFormalParameter && p.name?.lexeme == 'ref',
    );

    if (refParam == null) return;

    if (_isIdentifierUsed(buildMethod.body, 'ref')) return;

    if (_mixesInRefUsage(cls, localMixins)) return;

    rule.reportAtToken(cls.namePart.typeName);
  }

  static bool _mixesInRefUsage(
    ClassDeclaration cls,
    Map<String, MixinDeclaration> localMixins,
  ) {
    final mixins = cls.withClause?.mixinTypes;
    if (mixins == null) return false;

    for (final mixin in mixins) {
      final declaration = localMixins[mixin.name.lexeme];
      if (declaration != null) {
        if (_isIdentifierUsed(declaration.body, 'ref')) return true;
        continue;
      }

      final element = mixin.element;
      if (element is MixinElement && _isConstrainedToConsumerState(element)) {
        return true;
      }
    }

    return false;
  }

  static bool _isConstrainedToConsumerState(MixinElement mixin) => mixin
      .superclassConstraints
      .any(consumerStateChecker.isAssignableFromType);

  static bool _isIdentifierUsed(AstNode? node, String name) {
    if (node == null) return false;

    final visitor = _IdentifierVisitor(name);
    node.visitChildren(visitor);
    return visitor.used;
  }
}

class _IdentifierVisitor extends RecursiveAstVisitor<void> {
  final String name;
  bool used = false;

  _IdentifierVisitor(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier id) {
    if (id.name == name) used = true;
    super.visitSimpleIdentifier(id);
  }
}
