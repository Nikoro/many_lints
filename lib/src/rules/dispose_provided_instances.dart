import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../disposal_utils.dart';
import '../riverpod_type_checkers.dart';

class DisposeProvidedInstances extends ManyLintsRule {
  static const LintCode code = LintCode(
    'dispose_provided_instances',
    "Instance '{0}' has a dispose method but is not disposed via "
        'ref.onDispose().',
    correctionMessage:
        "Add 'ref.onDispose({0}.dispose)' to ensure proper resource cleanup.",
  );

  DisposeProvidedInstances()
    : super(
        name: 'dispose_provided_instances',
        description:
            'Warns when a disposable instance created inside a Riverpod '
            'provider or Notifier build() is not cleaned up via '
            'ref.onDispose().',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final DisposeProvidedInstances rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!_isProviderConstruction(node.staticType)) return;
    final callback = _extractProviderCallback(node.argumentList);
    if (callback == null) return;
    _checkCallbackBody(callback);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Edge case: an untyped `Provider((ref) => ...)` parses as a method invocation
    if (!_isProviderConstruction(node.staticType)) return;
    final callback = _extractProviderCallback(node.argumentList);
    if (callback == null) return;
    _checkCallbackBody(callback);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return;

    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !notifierChecker.isSuperOf(element)) return;

    _checkFunctionBody(node.body);
  }

  static FunctionExpression? _extractProviderCallback(
    ArgumentList argumentList,
  ) {
    final args = argumentList.arguments;
    if (args.isEmpty) return null;
    final firstArg = args.first;
    if (firstArg is FunctionExpression) return firstArg;
    return null;
  }

  static bool _isProviderConstruction(DartType? type) {
    if (type is! InterfaceType) return false;
    final name = type.element.name;
    if (name == null) return false;
    return _providerTypeNames.contains(name);
  }

  static const _providerTypeNames = {
    'Provider',
    'AutoDisposeProvider',
    'StateProvider',
    'AutoDisposeStateProvider',
    'StateNotifierProvider',
    'AutoDisposeStateNotifierProvider',
    'FutureProvider',
    'AutoDisposeFutureProvider',
    'StreamProvider',
    'AutoDisposeStreamProvider',
    'NotifierProvider',
    'AutoDisposeNotifierProvider',
    'AsyncNotifierProvider',
    'AutoDisposeAsyncNotifierProvider',
    'ChangeNotifierProvider',
    'AutoDisposeChangeNotifierProvider',
  };

  void _checkCallbackBody(FunctionExpression callback) {
    _checkFunctionBody(callback.body);
  }

  void _checkFunctionBody(FunctionBody body) {
    final cleanupMethods = resolveCleanupMethods(rule);

    final onDisposeCalls = _OnDisposeCollector(cleanupMethods);
    body.visitChildren(onDisposeCalls);
    final disposedSources = onDisposeCalls.disposedSources;

    final varFinder = _DisposableVariableFinder(cleanupMethods);
    body.visitChildren(varFinder);

    for (final variable in varFinder.variables) {
      final name = variable.name;
      final cleanupMethod = variable.cleanupMethod;

      if (disposedSources.contains('$name.$cleanupMethod') ||
          disposedSources.contains(name)) {
        continue;
      }

      rule.reportAtToken(variable.nameToken, arguments: [name]);
    }
  }
}

class _DisposableVariable {
  final String name;
  final Token nameToken;
  final String cleanupMethod;

  _DisposableVariable({
    required this.name,
    required this.nameToken,
    required this.cleanupMethod,
  });
}

class _DisposableVariableFinder extends RecursiveAstVisitor<void> {
  final List<_DisposableVariable> variables = [];

  final List<String> methods;

  _DisposableVariableFinder(this.methods);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final type = node.declaredFragment?.element.type;
    if (type == null) {
      super.visitVariableDeclaration(node);
      return;
    }

    final cleanupMethod = findCleanupMethod(type, methods: methods);
    if (cleanupMethod != null) {
      variables.add(
        _DisposableVariable(
          name: node.name.lexeme,
          nameToken: node.name,
          cleanupMethod: cleanupMethod,
        ),
      );
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

class _OnDisposeCollector extends RecursiveAstVisitor<void> {
  final Set<String> disposedSources = {};

  final List<String> methods;

  _OnDisposeCollector(this.methods);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'onDispose') {
      if (node.target case SimpleIdentifier(name: 'ref')) {
        _extractDisposedSource(node.argumentList);
      }
    }
    super.visitMethodInvocation(node);
  }

  void _extractDisposedSource(ArgumentList argumentList) {
    final args = argumentList.arguments;
    if (args.isEmpty) return;
    final arg = args.first;

    if (arg is PrefixedIdentifier) {
      disposedSources.add(arg.toSource());
      disposedSources.add(arg.prefix.name);
      return;
    }

    if (arg is PropertyAccess) {
      final target = arg.target;
      if (target is SimpleIdentifier) {
        disposedSources.add(arg.toSource());
        disposedSources.add(target.name);
      }
      return;
    }

    if (arg is FunctionExpression) {
      final callFinder = _CleanupCallFinder(methods);
      arg.body.visitChildren(callFinder);
      for (final source in callFinder.sources) {
        disposedSources.add(source);
      }
    }
  }
}

class _CleanupCallFinder extends RecursiveAstVisitor<void> {
  final Set<String> sources = {};

  final List<String> methods;

  _CleanupCallFinder(this.methods);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (methods.contains(node.methodName.name)) {
      final target = node.realTarget;
      if (target != null) {
        sources.add(target.toSource());
        sources.add('${target.toSource()}.${node.methodName.name}');
      }
    }
    super.visitMethodInvocation(node);
  }
}
