import 'package:analyzer/dart/element/element.dart';

import 'many_lints_rule.dart';
import 'type_checker.dart';

/// Flutter's own `State`, the base every `StatefulWidget` state extends.
const stateChecker = TypeChecker.fromName('State', packageName: 'flutter');

/// Whether [element] is a `State` subclass, honouring the rule's
/// `state_base_classes` option.
///
/// Fourteen rules in this package only apply inside a `State` subclass, and
/// each one used to pin Flutter's `State` directly. A project with a
/// `BaseState<T>` intermediate still satisfies that check — `isSuperOf` walks
/// the hierarchy — so the option is not about reaching those. It is about the
/// opposite case: a state-like base class that does *not* extend Flutter's
/// `State` at all, which every one of those rules silently skips.
///
/// `state_base_classes` names additional base types to treat as state:
///
/// ```yaml
/// rules:
///   dispose_fields:
///     state_base_classes: [DisposableController]
/// ```
///
/// Configured names are matched without a package pin, because a type
/// declared in the analyzed package has no `package:` URI to pin against.
/// Flutter's own `State` stays pinned, so the default behaviour is unchanged
/// and a user type coincidentally named `State` cannot silently widen a rule.
///
/// Must be called from inside a visitor callback: [ManyLintsRule.config] is
/// only resolved once the reporter for the current file has been set.
bool isStateElement(ManyLintsRule rule, Element element) {
  if (stateChecker.isSuperOf(element)) return true;

  final configured = rule.config.stringListOption('state_base_classes');
  if (configured.isEmpty) return false;

  for (final name in configured) {
    if (TypeChecker.fromName(name).isSuperOf(element)) return true;
  }
  return false;
}
