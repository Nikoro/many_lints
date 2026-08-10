import 'package:analyzer/dart/element/type.dart';

import 'many_lints_rule.dart';
import 'rule_config.dart';

/// Ordered list of cleanup method names to look for on disposable types.
///
/// Order is significant: it is the priority in which [findCleanupMethod]
/// picks a method when a type declares more than one.
const cleanupMethods = ['dispose', 'close', 'cancel'];

/// Returns the expected cleanup method name for a type, or `null` if the
/// type has no cleanup method.
///
/// Checks the type itself and all supertypes for methods named `dispose`,
/// `close`, or `cancel` (in that priority order), unless [methods] overrides
/// the list.
///
/// [methods] is a `List` rather than a `Set` precisely because the priority
/// order is part of the contract — a type declaring both `close` and `cancel`
/// must resolve deterministically.
String? findCleanupMethod(
  DartType type, {
  List<String> methods = cleanupMethods,
}) {
  if (type is! InterfaceType) return null;

  bool hasMethod(String name) {
    if (type.methods.any((m) => m.name == name)) return true;
    return type.element.allSupertypes.any(
      (s) => s.methods.any((m) => m.name == name),
    );
  }

  for (final cleanup in methods) {
    if (hasMethod(cleanup)) return cleanup;
  }
  return null;
}

/// Resolves the cleanup-method list for a rule, honouring `cleanup_methods`
/// (replaces the defaults) and `additional_cleanup_methods` (extends them).
///
/// Returns a `List` to preserve priority order: configured names are appended
/// after the base list, so a project's own `release()` is only chosen when the
/// type declares no standard cleanup method.
List<String> resolveCleanupMethods(ManyLintsRule rule) {
  return resolveCleanupMethodsFromConfig(rule.config);
}

/// Resolves cleanup method options from [config].
///
/// Kept separate from [resolveCleanupMethods] so replacement semantics can be
/// tested without a live analyzer rule. A present empty list is a deliberate
/// replacement with no methods; an absent or wrongly typed value falls back
/// to [cleanupMethods].
List<String> resolveCleanupMethodsFromConfig(RuleConfig config) {
  final rawReplacement = config.options['cleanup_methods'];
  final base = rawReplacement is List
      ? rawReplacement.whereType<String>().toList(growable: false)
      : cleanupMethods;

  final additional = config.stringListOption('additional_cleanup_methods');
  if (additional.isEmpty) return base;

  return [...base, ...additional];
}
