import 'package:analyzer/error/error.dart';

import '../class_suffix_validator.dart';

/// Warns if a Notifier class does not have the `Notifier` suffix.
class UseNotifierSuffix extends ClassSuffixValidator {
  static final LintCode code = LintCode(
    'use_notifier_suffix',
    'Use Notifier suffix',
    correctionMessage: 'Ex. {0}Notifier',
  );

  UseNotifierSuffix()
    : super(
        name: 'use_notifier_suffix',
        description:
            'Warns if a Notifier class does not have the Notifier suffix.',
        requiredSuffix: 'Notifier',
        baseClassName: 'Notifier',
        packageName: 'riverpod',
      );
}
