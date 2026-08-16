/// Shared machinery for the rules that reason about *where* a provider is read.
///
/// Riverpod and package:provider make the same distinction — subscribe
/// (`watch`) versus read once (`read`) — through two different receivers:
/// Riverpod's `ref`, which only a consumer has, and provider's `context`,
/// which every widget has. Every rule that cares about the distinction has to
/// tell the two apart the same way, so that test lives here.
library;

import 'package:analyzer/dart/ast/ast.dart';

import 'flutter_type_checkers.dart';
import 'riverpod_type_checkers.dart';

/// The receiver of [node] when it is a provider access named [method], or
/// `null` when it is an unrelated call.
///
/// Returns the receiver *as the author wrote it* — `'ref'` or `'context'` —
/// because that is what the diagnostic quotes back: telling a provider user to
/// swap `ref.read` for `ref.watch` names an API their project does not have.
///
/// `context` is matched on the receiver's **resolved type**, not its name. The
/// extension methods come from `package:provider` and can be called on any
/// expression of type `BuildContext`, so `widgetContext.read<T>()` and
/// `this.context.read<T>()` are the same call — while a local variable someone
/// happened to name `context` is not, unless it really is a `BuildContext`.
///
/// `ref` is matched on its type too, and that is load-bearing rather than
/// symmetric. While these rules only ran inside a *consumer*, a receiver named
/// `ref` could only be Riverpod's. Now that they admit every widget — which is
/// what covering provider requires — a plain widget holding a field of some
/// unrelated user-defined `Ref` class would report on the name alone. There is
/// a regression test for exactly that.
String? receiverKind(MethodInvocation node, String method) {
  if (node.methodName.name != method) return null;

  final target = node.realTarget;
  if (target == null) return null;

  final type = target.staticType;
  if (type == null) return null;

  if (riverpodRefChecker.isAssignableFromType(type)) return 'ref';
  if (buildContextChecker.isAssignableFromType(type)) return 'context';

  return null;
}
