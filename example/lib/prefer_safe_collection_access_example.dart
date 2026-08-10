// ignore_for_file: unused_element, unused_local_variable

// prefer_safe_collection_access
//
// `list.first` throws on an empty list; `list.head` returns `None`. Inside a
// pipeline the throw escapes the error channel entirely, so a StateError
// surfaces past every fold the caller wrote.

import 'package:fpdart/fpdart.dart';

class _Player {
  const _Player(this.name);
  final String name;
}

class _Team {
  _Team(this.players);
  final List<_Player> players;
}

// ❌ Bad: throws on an empty list, past the error channel
// LINT: use head
Option<_Player> badFirst(List<_Player> players) => Option.of(players.first);

// ❌ Bad: same for last
// LINT: use lastOption
TaskEither<String, _Player> badLast(List<_Player> players) =>
    TaskEither.of(players.last);

// ❌ Bad: a richer receiver is just as unsafe
// LINT: use head
Option<_Player> badNested(_Team team) => Option.of(team.players.first);

// ✅ Good: absence is a value the pipeline can carry
Option<_Player> goodHead(List<_Player> players) => players.head;

// ✅ Good: promote the empty case to a typed failure
TaskEither<String, _Player> goodPromoted(List<_Player> players) =>
    players.head.toEither(() => 'no players').toTaskEither();

// ✅ Good: the rest of the total family
Option<_Player> goodSingle(List<_Player> players) => players.singleOption;

Option<_Player> goodElementAt(List<_Player> players) =>
    players.elementAtOption(2);

// ✅ Good: outside a pipeline this is ordinary Dart, and is not reported by
// default. Set `report_outside_pipelines: true` to flag it too.
_Player goodOutsidePipeline(List<_Player> players) => players.first;
