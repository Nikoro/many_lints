import 'package:analyzer/dart/element/element.dart';

import 'many_lints_rule.dart';
import 'type_checker.dart';

const stateChecker = TypeChecker.fromName('State', packageName: 'flutter');

bool isStateElement(ManyLintsRule rule, Element element) {
  if (stateChecker.isSuperOf(element)) return true;

  final configured = rule.config.stringListOption('state_base_classes');
  if (configured.isEmpty) return false;

  for (final name in configured) {
    if (TypeChecker.fromName(name).isSuperOf(element)) return true;
  }
  return false;
}
