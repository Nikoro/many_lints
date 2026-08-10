import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'fpdart_type_checkers.dart';

/// One `<FpType>.Do(($) { ... })` invocation, with the pieces every
/// Do-notation rule needs already extracted.
///
/// `Do` is a factory constructor taking a single callback whose only parameter
/// is the extraction function conventionally named `$`. That makes `$` an
/// ordinary formal parameter rather than magic syntax, so rules read the
/// parameter's *declared name* instead of hardcoding `$` and a body written as
/// `TaskEither.Do((extract) async => ...)` is analyzed just the same.
///
/// ## Resolution rewrites the node, so only resolved code matches
///
/// `Option.Do(...)` parses as a [MethodInvocation] — `Option` is a generic
/// class written without type arguments, so `Option.Do` is syntactically
/// indistinguishable from a static method access. Resolution rewrites it into
/// an [InstanceCreationExpression] once `Do` is known to be a constructor.
///
/// Rules therefore register `addInstanceCreationExpression`, and a file where
/// fpdart fails to resolve matches nothing rather than matching wrongly. This
/// is worth stating because it is invisible in an unresolved AST dump: a
/// broken test stub leaves `MethodInvocationImpl` in the tree and makes it
/// look as though the rule targets the wrong node type.
class DoInvocation {
  /// The `<FpType>.Do(...)` expression itself.
  final InstanceCreationExpression node;

  /// The callback passed to `Do`.
  final FunctionExpression callback;

  /// The declared name of the extraction parameter — `$` by convention.
  ///
  /// Null when the callback declares no parameter, which cannot compile
  /// against fpdart's `DoFunction*` typedefs but can occur mid-edit.
  final String? extractorName;

  const DoInvocation({
    required this.node,
    required this.callback,
    required this.extractorName,
  });

  /// The callback's body.
  FunctionBody get body => callback.body;

  /// Whether the `Do` body is asynchronous.
  ///
  /// `TaskEither.Do` and `Task.Do` take an `async` callback and extract with
  /// `await $(...)`; `Either.Do`, `Option.Do` and the `IO*` variants are
  /// synchronous. Rules about `await` only apply to the former.
  bool get isAsync => body.isAsynchronous;

  /// Whether [expression] is a call to this block's extraction function.
  ///
  /// Matches `$(...)` written directly. A tear-off passed elsewhere and called
  /// from there is not matched, which is intentional: the pitfall rules are
  /// about lexical position, and a `$` that has escaped its frame is a
  /// different (rarer) problem than the ones they detect.
  bool isExtractorCall(Expression expression) {
    final name = extractorName;
    if (name == null) return false;

    // `$(step)` takes two shapes depending on what `$` resolves to. Called on
    // the block's own parameter it is a FunctionExpressionInvocation (the
    // target is a value, not a declared method); when the reference cannot be
    // resolved to a parameter it stays a bare MethodInvocation. Both spellings
    // read identically in source, so both must match.
    final invocation = expression.unParenthesized;

    if (invocation is FunctionExpressionInvocation) {
      final function = invocation.function;
      return function is SimpleIdentifier && function.name == name;
    }

    return invocation is MethodInvocation &&
        invocation.realTarget == null &&
        invocation.methodName.name == name;
  }

  /// Reads a `Do` invocation out of [node], or returns null when [node] is not
  /// one.
  static DoInvocation? tryRead(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    if (constructorName.name?.name != 'Do') return null;

    // Confirm this really is fpdart's `Do` rather than a user-defined
    // constructor that happens to share the name.
    final element = constructorName.element;
    if (element == null) return null;
    if (!anyFpdartChecker.isExactly(element.enclosingElement)) return null;

    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return null;

    final callback = arguments.first.argumentExpression;
    if (callback is! FunctionExpression) return null;

    final parameters = callback.parameters?.parameters;
    final extractorName = parameters == null || parameters.isEmpty
        ? null
        : parameters.first.name?.lexeme;

    return DoInvocation(
      node: node,
      callback: callback,
      extractorName: extractorName,
    );
  }
}

/// Visits a `Do` body, stopping at the boundary of any nested `Do`.
///
/// Three of the four Do-notation pitfalls are about what appears *directly*
/// inside one block. Without this boundary a nested block's contents would be
/// attributed to its parent, so a single mistake would be reported once per
/// enclosing level.
///
/// Nesting itself is a pitfall, reported separately by
/// `avoid_nested_do_notation`.
abstract class DoBodyVisitor extends RecursiveAstVisitor<void> {
  /// The block being visited.
  final DoInvocation invocation;

  DoBodyVisitor(this.invocation);

  /// Visits [invocation]'s body.
  void run() => invocation.body.accept(this);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Do not descend into a nested `Do`: its contents belong to that block.
    if (DoInvocation.tryRead(node) != null) return;
    super.visitInstanceCreationExpression(node);
  }
}
