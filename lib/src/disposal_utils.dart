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

  bool hasMethod(String name) {
    if (type.methods.any((m) => m.name == name)) return true;
    return type.element.allSupertypes.any(
      (s) => s.methods.any((m) => m.name == name),
    );
  }

  for (final cleanup in cleanupMethods) {
    if (hasMethod(cleanup)) return cleanup;
  }
  return null;
}
