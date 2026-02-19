import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when an instance with a `dispose` method is created inside a Riverpod
/// provider callback or Notifier `build()` method without a corresponding
/// `ref.onDispose()` call to clean it up.
///
/// Failing to properly dispose of resources can lead to memory leaks. When
/// objects with cleanup logic are created within providers but never cleaned
/// up, they retain memory unnecessarily.
class DisposeProvidedInstances extends AnalysisRule {
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
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    // For Provider((ref) => ...) callbacks
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
    // For Notifier/AsyncNotifier build() methods
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final DisposeProvidedInstances rule;

  _Visitor(this.rule);

  static const _notifierChecker = TypeChecker.any([
    TypeChecker.fromName('Notifier', packageName: 'riverpod'),
    TypeChecker.fromName('AsyncNotifier', packageName: 'riverpod'),
  ]);

  /// Cleanup methods to look for on created instances.
  static const _cleanupMethods = ['dispose', 'close', 'cancel'];

  // --- Provider callback detection ---

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Provider<T>((ref) => ...) or Provider<T>.autoDispose((ref) => ...)
    if (!_isProviderConstruction(node.staticType)) return;
    final callback = _extractProviderCallback(node.argumentList);
    if (callback == null) return;
    _checkCallbackBody(callback);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Provider((ref) => ...) without type args is parsed as MethodInvocation
    if (!_isProviderConstruction(node.staticType)) return;
    final callback = _extractProviderCallback(node.argumentList);
    if (callback == null) return;
    _checkCallbackBody(callback);
  }

  // --- Notifier build() detection ---

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return;

    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !_notifierChecker.isSuperOf(element)) return;

    _checkFunctionBody(node.body);
  }

  // --- Shared analysis logic ---

  /// Extracts the first positional argument as a FunctionExpression from
  /// a provider constructor's argument list.
  static FunctionExpression? _extractProviderCallback(
    ArgumentList argumentList,
  ) {
    final args = argumentList.arguments;
    if (args.isEmpty) return null;
    final firstArg = args.first;
    if (firstArg is FunctionExpression) return firstArg;
    return null;
  }

  /// Checks whether [type] is a Riverpod Provider type.
  static bool _isProviderConstruction(DartType? type) {
    if (type is! InterfaceType) return false;
    final name = type.element.name;
    if (name == null) return false;
    // Match common Riverpod provider types
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
    // Collect all ref.onDispose(...) calls
    final onDisposeCalls = _OnDisposeCollector();
    body.visitChildren(onDisposeCalls);
    final disposedSources = onDisposeCalls.disposedSources;

    // Find all variable declarations with disposable types
    final varFinder = _DisposableVariableFinder();
    body.visitChildren(varFinder);

    for (final variable in varFinder.variables) {
      final name = variable.name;
      final cleanupMethod = variable.cleanupMethod;

      // Check if ref.onDispose is called with this variable's cleanup method
      // Common patterns:
      //   ref.onDispose(instance.dispose)
      //   ref.onDispose(() => instance.dispose())
      //   ref.onDispose(() { instance.dispose(); })
      if (disposedSources.contains('$name.$cleanupMethod') ||
          disposedSources.contains(name)) {
        continue;
      }

      rule.reportAtToken(variable.nameToken, arguments: [name]);
    }
  }

  /// Returns the expected cleanup method name for a type, or `null` if the
  /// type has no cleanup method.
  static String? _findCleanupMethod(DartType type) {
    if (type is! InterfaceType) return null;

    final allMethods = <String>{};
    for (final method in type.methods) {
      final name = method.name;
      if (name != null) allMethods.add(name);
    }
    for (final supertype in type.element.allSupertypes) {
      for (final method in supertype.methods) {
        final name = method.name;
        if (name != null) allMethods.add(name);
      }
    }

    for (final cleanup in _cleanupMethods) {
      if (allMethods.contains(cleanup)) return cleanup;
    }
    return null;
  }
}

/// Info about a variable with a disposable type found in the body.
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

/// Collects variable declarations whose types have cleanup methods.
class _DisposableVariableFinder extends RecursiveAstVisitor<void> {
  final List<_DisposableVariable> variables = [];

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final type = node.declaredFragment?.element.type;
    if (type == null) {
      super.visitVariableDeclaration(node);
      return;
    }

    final cleanupMethod = _Visitor._findCleanupMethod(type);
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

  // Stop at nested function boundaries
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

/// Collects sources disposed via `ref.onDispose(...)`.
///
/// Detects patterns like:
/// - `ref.onDispose(instance.dispose)` → records `instance.dispose`
/// - `ref.onDispose(instance.close)` → records `instance.close`
/// - `ref.onDispose(() => instance.dispose())` → records `instance`
/// - `ref.onDispose(() { instance.dispose(); })` → records `instance`
class _OnDisposeCollector extends RecursiveAstVisitor<void> {
  /// Set of source patterns that are disposed.
  /// Contains entries like `instance.dispose` (tear-off) or `instance` (lambda).
  final Set<String> disposedSources = {};

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

    // ref.onDispose(instance.dispose) — tear-off
    if (arg is PrefixedIdentifier) {
      // e.g., instance.dispose → record both forms
      disposedSources.add(arg.toSource());
      disposedSources.add(arg.prefix.name);
      return;
    }

    // ref.onDispose(instance.dispose) via PropertyAccess (chained)
    if (arg is PropertyAccess) {
      final target = arg.target;
      if (target is SimpleIdentifier) {
        disposedSources.add(arg.toSource());
        disposedSources.add(target.name);
      }
      return;
    }

    // ref.onDispose(() => instance.dispose())
    // ref.onDispose(() { instance.dispose(); })
    if (arg is FunctionExpression) {
      final callFinder = _CleanupCallFinder();
      arg.body.visitChildren(callFinder);
      for (final source in callFinder.sources) {
        disposedSources.add(source);
      }
    }
  }

  // Stop at nested function boundaries
  @override
  void visitFunctionExpression(FunctionExpression node) {
    // But still visit the function expression if it's an argument to onDispose
    // This is handled via _extractDisposedSource above, so just visit normally
    // for other cases
    super.visitFunctionExpression(node);
  }
}

/// Finds cleanup method calls (dispose/close/cancel) inside a lambda and
/// records the target variable name.
class _CleanupCallFinder extends RecursiveAstVisitor<void> {
  final Set<String> sources = {};

  static const _cleanupMethods = {'dispose', 'close', 'cancel'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_cleanupMethods.contains(node.methodName.name)) {
      final target = node.realTarget;
      if (target != null) {
        sources.add(target.toSource());
        // Also record tear-off form
        sources.add('${target.toSource()}.${node.methodName.name}');
      }
    }
    super.visitMethodInvocation(node);
  }
}
