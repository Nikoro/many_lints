import 'package:analyzer/dart/element/type.dart';

/// Ordered list of cleanup method names to look for on disposable types.
const cleanupMethods = ['dispose', 'close', 'cancel'];

/// Returns the expected cleanup method name for a type, or `null` if the
/// type has no cleanup method.
///
/// Checks the type itself and all supertypes for methods named `dispose`,
/// `close`, or `cancel` (in that priority order).
String? findCleanupMethod(DartType type) {
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

  for (final cleanup in cleanupMethods) {
    if (allMethods.contains(cleanup)) return cleanup;
  }
  return null;
}
