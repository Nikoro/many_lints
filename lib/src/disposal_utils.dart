import 'package:analyzer/dart/element/type.dart';

import 'many_lints_rule.dart';
import 'rule_config.dart';

const cleanupMethods = ['dispose', 'close', 'cancel'];

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

List<String> resolveCleanupMethods(ManyLintsRule rule) {
  return resolveCleanupMethodsFromConfig(rule.config);
}

List<String> resolveCleanupMethodsFromConfig(RuleConfig config) {
  final rawReplacement = config.options['cleanup_methods'];
  final base = rawReplacement is List
      ? rawReplacement.whereType<String>().toList(growable: false)
      : cleanupMethods;

  final additional = config.stringListOption('additional_cleanup_methods');
  if (additional.isEmpty) return base;

  return [...base, ...additional];
}
