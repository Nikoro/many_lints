import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../type_checker.dart';

/// Warns when a ConsumerWidget does not use WidgetRef.
class AvoidUnnecessaryConsumerWidgets extends AnalysisRule {
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
  void registerNodeProcessors(
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

  static const _consumerWidgetChecker = TypeChecker.fromName(
    'ConsumerWidget',
    packageName: 'flutter_riverpod',
  );

  static const _consumerStatefulWidgetChecker = TypeChecker.fromName(
    'ConsumerStatefulWidget',
    packageName: 'flutter_riverpod',
  );

  static const _consumerStateChecker = TypeChecker.any([
    TypeChecker.fromName('ConsumerState', packageName: 'flutter_riverpod'),
    TypeChecker.fromName('HookConsumerState', packageName: 'hooks_riverpod'),
  ]);

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

      if (_consumerStatefulWidgetChecker.isSuperOf(element)) {
        consumerStatefulWidgets.add(declaration);
      } else if (_consumerStateChecker.isSuperOf(element)) {
        consumerStates.add(declaration);
      } else {
        _checkConsumerWidget(declaration, localMixins);
      }
    }

    for (final widget in consumerStatefulWidgets) {
      final widgetName = widget.namePart.typeName.lexeme;

      final stateClass = _findStateClass(consumerStates, widgetName);
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

    if (!_consumerWidgetChecker.isExactly(superclassElement)) return;

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

  /// Finds the ConsumerState class that corresponds to the given widget name.
  /// Looks for `ConsumerState<WidgetName>` in the extends clause.
  static ClassDeclaration? _findStateClass(
    List<ClassDeclaration> stateClasses,
    String widgetName,
  ) {
    for (final stateClass in stateClasses) {
      final superclass = stateClass.extendsClause?.superclass;
      if (superclass == null) continue;

      final typeArgs = superclass.typeArguments?.arguments;
      if (typeArgs != null && typeArgs.length == 1) {
        final typeArg = typeArgs.first;
        if (typeArg is NamedType && typeArg.name.lexeme == widgetName) {
          return stateClass;
        }
      }
    }
    return null;
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
        if (_consumerStateChecker.isAssignableFromType(constraint)) return true;
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
