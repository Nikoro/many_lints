// ignore_for_file: unused_element

import 'package:flutter/material.dart';

// use_sliver_prefix
//
// Widgets that return sliver widgets should have the 'Sliver' prefix
// in their class name.

// ❌ Bad: Returns a sliver widget but lacks the 'Sliver' prefix

// LINT: Returns SliverToBoxAdapter but name doesn't start with 'Sliver'
class MyAdapter extends StatelessWidget {
  const MyAdapter({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: Text('hello'));
  }
}

// LINT: Returns SliverList but name doesn't start with 'Sliver'
class _ProductList extends StatelessWidget {
  const _ProductList();

  @override
  Widget build(BuildContext context) {
    return SliverList(delegate: SliverChildListDelegate([]));
  }
}

// LINT: StatefulWidget whose State returns a sliver
class _HeaderBar extends StatefulWidget {
  const _HeaderBar();

  @override
  State<_HeaderBar> createState() => _HeaderBarState();
}

class _HeaderBarState extends State<_HeaderBar> {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(title: const Text('Title'));
  }
}

// ✅ Good: Has the 'Sliver' prefix

class SliverMyAdapter extends StatelessWidget {
  const SliverMyAdapter({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: Text('hello'));
  }
}

class _SliverProductList extends StatelessWidget {
  const _SliverProductList();

  @override
  Widget build(BuildContext context) {
    return SliverList(delegate: SliverChildListDelegate([]));
  }
}

// ✅ Good: Returns a non-sliver widget (no prefix needed)

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(child: Text('hello'));
  }
}
