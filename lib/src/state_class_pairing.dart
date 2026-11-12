import 'package:analyzer/dart/ast/ast.dart';

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
