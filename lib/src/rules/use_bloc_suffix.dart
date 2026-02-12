import 'package:analyzer/error/error.dart';

import '../class_suffix_validator.dart';

/// Warns if a Bloc class does not have the `Bloc` suffix.
class UseBlocSuffix extends ClassSuffixValidator {
  static final LintCode code = LintCode(
    'use_bloc_suffix',
    'Use Bloc suffix',
    correctionMessage: 'Ex. {0}Bloc',
  );

  UseBlocSuffix()
    : super(
        name: 'use_bloc_suffix',
        description: 'Warns if a Bloc class does not have the Bloc suffix.',
        requiredSuffix: 'Bloc',
        baseClassName: 'Bloc',
        packageName: 'bloc',
      );
}
