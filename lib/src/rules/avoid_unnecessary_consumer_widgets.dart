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

/// Warns when a ConsumerWidget does not use WidgetRef.
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
    // `ConsumerStatefulWidget` keeps its `ref` in the companion `ConsumerState`,
    // so the two declarations have to be correlated before deciding.
    final consumerStatefulWidgets = <ClassDeclaration>[];
    final consumerStates = <ClassDeclaration>[];
    // Mixin declarations in this unit, so a `ref` usage hidden in one of them
    // can be found; mixins from other files are covered by their elements.
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

      // `ref` is a getter on `ConsumerState`, usable from every member, so the
      // whole class body counts — not just `build`.
      if (_isIdentifierUsed(stateClass.body, 'ref')) continue;
      if (_mixesInRefUsage(stateClass, localMixins)) continue;

      rule.reportAtToken(widget.namePart.typeName);
    }
  }

  /// Reports a `ConsumerWidget` whose `build` never touches its `ref`.
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

    // A mixin applied to the widget can consume the `ref` that `build` forwards
    // to it, which leaves `build` itself looking ref-free.
    if (_mixesInRefUsage(cls, localMixins)) return;

    rule.reportAtToken(cls.namePart.typeName);
  }

  /// Whether a mixin applied to the class uses the `ref` on its behalf.
  ///
  /// Sharing provider access through a mixin `on ConsumerState<T>` is a normal
  /// pattern: the mixin holds the `ref.watch`/`ref.read` calls, which leaves
  /// the class body looking ref-free while the widget genuinely needs the
  /// Riverpod container. Only the declaration carries the method bodies, so a
  /// local mixin is inspected via the AST; a mixin from another file is
  /// recognised by it being constrained to a Riverpod state class, since its
  /// superclass constraint is the reason it can reach a `ref` at all.
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

      // Out-of-file mixin: its bodies are gone, but a superclass constraint on
      // a Riverpod state class means it exists to work with `ref`.
      final element = mixin.element;
      if (element is! MixinElement) continue;

      for (final constraint in element.superclassConstraints) {
        if (consumerStateChecker.isAssignableFromType(constraint)) return true;
      }
    }

    return false;
  }

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
