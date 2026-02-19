import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_multi_bloc_provider.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferMultiBlocProviderTest),
  );
}

@reflectiveTest
class PreferMultiBlocProviderTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferMultiBlocProvider();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
class BlocBase<State> {
  BlocBase(State initialState);
}
class Bloc<Event, State> extends BlocBase<State> {
  Bloc(super.initialState);
}
class Cubit<State> extends BlocBase<State> {
  Cubit(super.initialState);
}
''');
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
class Key {}
class Widget {}
''');
    newPackage('flutter_bloc').addFile('lib/flutter_bloc.dart', r'''
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

export 'package:bloc/bloc.dart';

class BlocProvider<T extends BlocBase> extends Widget {
  final T Function(BuildContext) create;
  final Widget child;
  final bool lazy;

  const BlocProvider({
    Key? key,
    required this.create,
    required this.child,
    this.lazy = true,
  });
}

class MultiBlocProvider extends Widget {
  final List<BlocProvider> providers;
  final Widget child;

  const MultiBlocProvider({
    Key? key,
    required this.providers,
    required this.child,
  });
}

class BlocListener<B extends BlocBase, S> extends Widget {
  final void Function(BuildContext, S)? listener;
  final Widget child;

  const BlocListener({
    Key? key,
    this.listener,
    required this.child,
  });
}

class MultiBlocListener extends Widget {
  final List<BlocListener> listeners;
  final Widget child;

  const MultiBlocListener({
    Key? key,
    required this.listeners,
    required this.child,
  });
}

class RepositoryProvider<T> extends Widget {
  final T Function(BuildContext) create;
  final Widget child;

  const RepositoryProvider({
    Key? key,
    required this.create,
    required this.child,
  });
}

class MultiRepositoryProvider extends Widget {
  final List<RepositoryProvider> providers;
  final Widget child;

  const MultiRepositoryProvider({
    Key? key,
    required this.providers,
    required this.child,
  });
}
''');
    super.setUp();
  }

  // --- BlocProvider tests ---

  Future<void> test_nestedBlocProviders() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocA extends Cubit<int> { BlocA() : super(0); }
class BlocB extends Cubit<int> { BlocB() : super(0); }

final provider = BlocProvider<BlocA>(
  create: (context) => BlocA(),
  child: BlocProvider<BlocB>(
    create: (context) => BlocB(),
    child: Widget(),
  ),
);
''',
      [lint(217, 19)],
    );
  }

  Future<void> test_tripleNestedBlocProviders() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocA extends Cubit<int> { BlocA() : super(0); }
class BlocB extends Cubit<int> { BlocB() : super(0); }
class BlocC extends Cubit<int> { BlocC() : super(0); }

final provider = BlocProvider<BlocA>(
  create: (context) => BlocA(),
  child: BlocProvider<BlocB>(
    create: (context) => BlocB(),
    child: BlocProvider<BlocC>(
      create: (context) => BlocC(),
      child: Widget(),
    ),
  ),
);
''',
      [lint(272, 19)],
    );
  }

  Future<void> test_singleBlocProvider_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocA extends Cubit<int> { BlocA() : super(0); }

final provider = BlocProvider<BlocA>(
  create: (context) => BlocA(),
  child: Widget(),
);
''');
  }

  Future<void> test_multiBlocProviderAlready_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocA extends Cubit<int> { BlocA() : super(0); }
class BlocB extends Cubit<int> { BlocB() : super(0); }

final provider = MultiBlocProvider(
  providers: [
    BlocProvider<BlocA>(
      create: (context) => BlocA(),
      child: Widget(),
    ),
    BlocProvider<BlocB>(
      create: (context) => BlocB(),
      child: Widget(),
    ),
  ],
  child: Widget(),
);
''');
  }

  // --- BlocListener tests ---

  Future<void> test_nestedBlocListeners() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocA extends Cubit<int> { BlocA() : super(0); }
class BlocB extends Cubit<int> { BlocB() : super(0); }

final listener = BlocListener<BlocA, int>(
  listener: (context, state) {},
  child: BlocListener<BlocB, int>(
    listener: (context, state) {},
    child: Widget(),
  ),
);
''',
      [lint(217, 24)],
    );
  }

  Future<void> test_singleBlocListener_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocA extends Cubit<int> { BlocA() : super(0); }

final listener = BlocListener<BlocA, int>(
  listener: (context, state) {},
  child: Widget(),
);
''');
  }

  // --- RepositoryProvider tests ---

  Future<void> test_nestedRepositoryProviders() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RepoA {}
class RepoB {}

final provider = RepositoryProvider<RepoA>(
  create: (context) => RepoA(),
  child: RepositoryProvider<RepoB>(
    create: (context) => RepoB(),
    child: Widget(),
  ),
);
''',
      [lint(137, 25)],
    );
  }

  Future<void> test_singleRepositoryProvider_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RepoA {}

final provider = RepositoryProvider<RepoA>(
  create: (context) => RepoA(),
  child: Widget(),
);
''');
  }

  // --- Mixed types: should NOT trigger ---

  Future<void>
  test_blocProviderWithRepositoryProviderChild_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocA extends Cubit<int> { BlocA() : super(0); }
class RepoA {}

final provider = BlocProvider<BlocA>(
  create: (context) => BlocA(),
  child: RepositoryProvider<RepoA>(
    create: (context) => RepoA(),
    child: Widget(),
  ),
);
''');
  }

  // --- Only outermost reports ---

  Future<void> test_onlyOutermostReports() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocA extends Cubit<int> { BlocA() : super(0); }
class BlocB extends Cubit<int> { BlocB() : super(0); }
class BlocC extends Cubit<int> { BlocC() : super(0); }

final provider = BlocProvider<BlocA>(
  create: (context) => BlocA(),
  child: BlocProvider<BlocB>(
    create: (context) => BlocB(),
    child: BlocProvider<BlocC>(
      create: (context) => BlocC(),
      child: Widget(),
    ),
  ),
);
''',
      [lint(272, 19)],
    );
  }
}
