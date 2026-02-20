import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `setState` is called directly inside `initState`,
/// `didUpdateWidget`, or `build` methods in a `State` subclass.
///
/// In `initState` and `didUpdateWidget`, calling `setState` is unnecessary
/// because the framework will call `build` after these methods return anyway.
/// In `build`, calling `setState` triggers an additional rebuild which causes
/// performance issues.
///
/// For event handler callbacks (onPressed, onTap, etc.) inside `build`,
/// `setState` is allowed since those run asynchronously.
class AvoidUnnecessarySetstate extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_setstate',
    "Unnecessary call to 'setState' inside '{0}'.",
    correctionMessage:
        'Mutate the state directly without calling setState in this method.',
  );

  AvoidUnnecessarySetstate()
    : super(
        name: 'avoid_unnecessary_setstate',
        description:
            'Warns when setState is called in initState, didUpdateWidget, '
            'or build where it is unnecessary.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessarySetstate rule;

  _Visitor(this.rule);

  static const _stateChecker = TypeChecker.fromName(
    'State',
    packageName: 'flutter',
  );

  /// Lifecycle methods where setState is unnecessary.
  static const _lifecycleMethods = {'initState', 'didUpdateWidget', 'build'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'setState') return;

    // Single parent-chain walk: find lifecycle method and enclosing class.
    final (:method, :classDecl) = _findLifecycleMethodAndClass(node);
    if (method == null || classDecl == null) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !_stateChecker.isSuperOf(element)) return;

    final methodName = method.name.lexeme;

    // For build method, skip setState inside event handler callbacks
    if (methodName == 'build' && _isInsideEventHandlerCallback(node)) return;

    rule.reportAtNode(node, arguments: [methodName]);
  }

  /// Walks up the AST once to find both the nearest lifecycle method and
  /// the enclosing class declaration, stopping at function boundaries.
  static ({MethodDeclaration? method, ClassDeclaration? classDecl})
  _findLifecycleMethodAndClass(AstNode node) {
    MethodDeclaration? method;
    AstNode? current = node.parent;
    while (current != null) {
      if (method == null) {
        // Still looking for the lifecycle method
        if (current is FunctionExpression || current is FunctionDeclaration) {
          return (method: null, classDecl: null);
        }
        if (current is MethodDeclaration) {
          final name = current.name.lexeme;
          if (!_lifecycleMethods.contains(name)) {
            return (method: null, classDecl: null);
          }
          method = current;
        }
      } else if (current is ClassDeclaration) {
        return (method: method, classDecl: current);
      }
      current = current.parent;
    }
    return (method: null, classDecl: null);
  }

  /// Checks whether the setState call is inside a closure that is passed
  /// as a named argument (i.e., an event handler like onPressed, onTap).
  ///
  /// This allows patterns like:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return ElevatedButton(
  ///     onPressed: () {
  ///       setState(() { ... }); // OK — this is an event handler
  ///     },
  ///     child: Text('Press'),
  ///   );
  /// }
  /// ```
  static bool _isInsideEventHandlerCallback(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      // If we hit a MethodDeclaration, we've exited the closure scope
      if (current is MethodDeclaration) return false;

      // Check if we're inside a FunctionExpression that is the value of
      // a NamedExpression (e.g., onPressed: () { ... })
      if (current is FunctionExpression) {
        final parent = current.parent;
        if (parent is NamedExpression) return true;
      }

      current = current.parent;
    }
    return false;
  }
}
