import 'package:analyzer/error/error.dart';

import '../class_affix_validator.dart';

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
