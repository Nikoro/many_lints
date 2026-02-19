// ignore_for_file: unused_local_variable

// prefer_multi_bloc_provider
//
// Warns when nested BlocProvider, BlocListener, or RepositoryProvider
// widgets can be consolidated using their Multi* counterpart.

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

class TimerCubit extends Cubit<int> {
  TimerCubit() : super(0);
}

class AuthRepository {}

class AnalyticsRepository {}

// ❌ Bad: Nested BlocProviders
final badBlocProviders = BlocProvider<CounterBloc>(
  create: (context) => CounterBloc(),
  // LINT: Prefer MultiBlocProvider instead of multiple nested BlocProviders
  child: BlocProvider<TimerCubit>(
    create: (context) => TimerCubit(),
    child: Container(),
  ),
);

// ❌ Bad: Nested RepositoryProviders
final badRepoProviders = RepositoryProvider<AuthRepository>(
  create: (context) => AuthRepository(),
  // LINT: Prefer MultiRepositoryProvider instead of nested RepositoryProviders
  child: RepositoryProvider<AnalyticsRepository>(
    create: (context) => AnalyticsRepository(),
    child: Container(),
  ),
);

// ❌ Bad: Nested BlocListeners
final badListeners = BlocListener<CounterBloc, int>(
  listener: (context, state) {},
  // LINT: Prefer MultiBlocListener instead of nested BlocListeners
  child: BlocListener<TimerCubit, int>(
    listener: (context, state) {},
    child: Container(),
  ),
);

// ✅ Good: Using MultiBlocProvider
final goodBlocProviders = MultiBlocProvider(
  providers: [
    BlocProvider<CounterBloc>(create: (context) => CounterBloc()),
    BlocProvider<TimerCubit>(create: (context) => TimerCubit()),
  ],
  child: Container(),
);

// ✅ Good: Using MultiRepositoryProvider
final goodRepoProviders = MultiRepositoryProvider(
  providers: [
    RepositoryProvider<AuthRepository>(create: (context) => AuthRepository()),
    RepositoryProvider<AnalyticsRepository>(
      create: (context) => AnalyticsRepository(),
    ),
  ],
  child: Container(),
);

// ✅ Good: Using MultiBlocListener
final goodListeners = MultiBlocListener(
  listeners: [
    BlocListener<CounterBloc, int>(listener: (context, state) {}),
    BlocListener<TimerCubit, int>(listener: (context, state) {}),
  ],
  child: Container(),
);

// ✅ Good: Single provider (no nesting, no lint)
final singleProvider = BlocProvider<CounterBloc>(
  create: (context) => CounterBloc(),
  child: Container(),
);

// ✅ Good: Mixed types (BlocProvider + RepositoryProvider) — no lint
final mixedProviders = BlocProvider<CounterBloc>(
  create: (context) => CounterBloc(),
  child: RepositoryProvider<AuthRepository>(
    create: (context) => AuthRepository(),
    child: Container(),
  ),
);
