import 'package:analyzer/error/error.dart';

import '../class_suffix_validator.dart';

/// Warns if a Cubit class does not have the `Cubit` suffix.
class UseCubitSuffix extends ClassSuffixValidator {
  static final LintCode code = LintCode(
    'use_cubit_suffix',
    'Use Cubit suffix',
    correctionMessage: 'Ex. {0}Cubit',
  );

  UseCubitSuffix()
    : super(
        name: 'use_cubit_suffix',
        description: 'Warns if a Cubit class does not have the Cubit suffix.',
        requiredSuffix: 'Cubit',
        baseClassName: 'Cubit',
        packageName: 'bloc',
      );
}
