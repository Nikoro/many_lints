// arguments_ordering
//
// Detects a call whose NAMED arguments are not in the configured order.
// Positional arguments are never ordered: their order is the call's meaning.
//
//   arguments_ordering:
//     order: alphabetical

void card({
  int? borderRadius,
  int? color,
  int? elevation,
  int? margin,
  int? padding,
}) {}

void positional(int a, int b, int c, int d, int e) {}

void badExample() {
  // LINT: the argument 'color' is out of order
  card(elevation: 2, color: 1, padding: 0, margin: 0, borderRadius: 0);
}

void goodExample() {
  card(borderRadius: 0, color: 1, elevation: 2, margin: 0, padding: 0);
}

void edgeCases() {
  // Positional arguments are left alone: reordering them changes the call.
  positional(5, 4, 3, 2, 1);

  // Below `min_arguments`, order carries no cost.
  card(elevation: 2, color: 1);
}
// ignore_for_file: many_lints/avoid_long_parameter_list
