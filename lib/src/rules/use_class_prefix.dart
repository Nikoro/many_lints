import 'package:analyzer/error/error.dart';

import '../class_affix_validator.dart';

/// Warns when a class deriving from a configured type lacks the required
/// name prefix.
///
/// This rule reports nothing until it is configured — it enforces *your*
/// naming convention, not a built-in one. A type matches whether it is
/// reached by `extends`, `implements`, `with`, or an indirect ancestor.
///
/// **Configuration** (`many_lints.yaml`):
///
/// ```yaml
/// rules:
///   use_class_prefix:
///     ignore_private: true        # rule-wide default, optional
///     entries:
///       - type: Repository
///         package: my_data        # optional; omit to match any package
///         prefix: Db
/// ```
///
/// **BAD:**
/// ```dart
/// class UserRepository implements Repository<User> {}  // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// class DbUserRepository implements Repository<User> {}
/// ```
class UseClassPrefix extends ClassAffixValidator {
  static const LintCode code = LintCode(
    'use_class_prefix',
    "Class '{1}' does not start with the required '{0}' prefix.",
    correctionMessage: "Rename the class to start with '{0}'.",
  );

  UseClassPrefix()
    : super(
        name: 'use_class_prefix',
        description:
            'Warns when a class deriving from a configured type lacks the '
            'required name prefix.',
        kind: AffixKind.prefix,
      );

  @override
  LintCode get diagnosticCode => code;
}
