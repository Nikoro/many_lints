/// Pairs a `StatefulWidget` declaration with its companion `State` class.
///
/// A widget and its state are two separate top-level declarations, so a rule
/// that reasons about both has to correlate them itself. The only link the
/// source gives is the type argument on the state's `extends State<Widget>`
/// clause (or `ConsumerState<Widget>`, and so on), so the match is made on that
/// argument's name rather than on any naming convention — `_FooState` is a
/// habit, not a requirement.
library;

import 'package:analyzer/dart/ast/ast.dart';

/// Returns the class in [stateClasses] whose `extends` clause is parameterised
/// with [widgetName], or `null` when no state class names that widget.
///
/// Only a single type argument counts: a state base takes exactly one, so
/// anything else is a different kind of superclass.
ClassDeclaration? findStateClassFor(
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
