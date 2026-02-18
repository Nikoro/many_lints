// ignore_for_file: unused_local_variable

// avoid_shrink_wrap_in_lists
//
// Warns when a ListView uses shrinkWrap: true, which is expensive
// performance-wise. Prefer using CustomScrollView with SliverList instead.

import 'package:flutter/widgets.dart';

// ❌ Bad: Using shrinkWrap: true in ListView
class BadExamples {
  // LINT: ListView with shrinkWrap: true
  final a = ListView(shrinkWrap: true);

  // LINT: ListView.builder with shrinkWrap: true
  final b = ListView.builder(
    shrinkWrap: true,
    itemCount: 10,
    itemBuilder: (context, index) => Text('$index'),
  );

  // LINT: ListView.separated with shrinkWrap: true
  final c = ListView.separated(
    shrinkWrap: true,
    itemCount: 10,
    itemBuilder: (context, index) => Text('$index'),
    separatorBuilder: (context, index) => const SizedBox(height: 8),
  );
}

// ✅ Good: ListView without shrinkWrap or using slivers
class GoodExamples {
  // ListView without shrinkWrap
  final a = ListView(children: const [Text('hello')]);

  // ListView with shrinkWrap explicitly false
  final b = ListView(shrinkWrap: false);

  // CustomScrollView with SliverList for better performance
  final c = CustomScrollView(
    slivers: [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Text('$index'),
          childCount: 10,
        ),
      ),
    ],
  );
}
