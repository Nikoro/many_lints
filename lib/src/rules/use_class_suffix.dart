import 'package:analyzer/error/error.dart';

import '../class_affix_validator.dart';

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
