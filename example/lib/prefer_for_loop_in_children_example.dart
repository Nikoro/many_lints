// ignore_for_file: unused_local_variable

import 'package:flutter/widgets.dart';

// prefer_for_loop_in_children
//
// Prefer using collection-for syntax instead of functional approaches
// (.map().toList(), List.generate(), .fold(), spread with .map())
// to build widget lists.

// ❌ Bad: .map().toList()
class BadMapToList extends StatelessWidget {
  const BadMapToList({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['a', 'b', 'c'];
    return Column(
      // LINT: Prefer using a for-loop instead of functional list building
      children: items.map((item) => Text(item)).toList(),
    );
  }
}

// ❌ Bad: spread with .map()
class BadSpreadMap extends StatelessWidget {
  const BadSpreadMap({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['a', 'b', 'c'];
    return Column(
      children: [
        const Text('Header'),
        // LINT: Prefer using a for-loop
        ...items.map((item) => Text(item)),
      ],
    );
  }
}

// ❌ Bad: List.generate()
class BadListGenerate extends StatelessWidget {
  const BadListGenerate({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      // LINT: Prefer using a for-loop
      children: List.generate(5, (index) => Text('Item $index')),
    );
  }
}

// ❌ Bad: .fold() to accumulate widgets
Widget badFold(List<String> items) {
  // LINT: Prefer using a for-loop
  final widgets = items.fold<List<Widget>>([], (list, item) {
    list.add(Text(item));
    return list;
  });
  return Column(children: widgets);
}

// ✅ Good: collection-for syntax
class GoodForLoop extends StatelessWidget {
  const GoodForLoop({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['a', 'b', 'c'];
    return Column(children: [for (final item in items) Text(item)]);
  }
}

// ✅ Good: collection-for with index
class GoodForLoopWithIndex extends StatelessWidget {
  const GoodForLoopWithIndex({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [for (var i = 0; i < 5; i++) Text('Item $i')]);
  }
}

// ✅ Good: for-loop mixed with other children
class GoodMixed extends StatelessWidget {
  const GoodMixed({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['a', 'b', 'c'];
    return Column(
      children: [
        const Text('Header'),
        for (final item in items) Text(item),
        const Text('Footer'),
      ],
    );
  }
}
