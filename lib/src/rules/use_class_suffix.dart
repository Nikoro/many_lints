import 'package:analyzer/error/error.dart';

import '../class_affix_validator.dart';

/// Warns when a class deriving from a configured type lacks the required
/// name suffix.
///
/// This rule reports nothing until it is configured — it enforces *your*
/// naming convention, not a built-in one. A type matches whether it is
/// reached by `extends`, `implements`, `with`, or an indirect ancestor.
///
/// **Configuration** (`many_lints.yaml`):
///
/// ```yaml
/// rules:
///   use_class_suffix:
///     ignore_private: true        # rule-wide default, optional
///     entries:
///       - type: Bloc
///         package: bloc           # optional; omit to match any package
///         suffix: Bloc
///       - type: Repository        # a type from your own package
///         suffix: Repository
/// ```
///
/// **BAD:**
/// ```dart
/// class Counter extends Bloc<CounterEvent, int> {}  // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// class CounterBloc extends Bloc<CounterEvent, int> {}
/// ```
class UseClassSuffix extends ClassAffixValidator {
  static const LintCode code = LintCode(
    'use_class_suffix',
    "Class '{1}' does not end with the required '{0}' suffix.",
    correctionMessage: "Rename the class to end with '{0}'.",
  );

  UseClassSuffix()
    : super(
        name: 'use_class_suffix',
        description:
            'Warns when a class deriving from a configured type lacks the '
            'required name suffix.',
        kind: AffixKind.suffix,
      );

  @override
  LintCode get diagnosticCode => code;
}
