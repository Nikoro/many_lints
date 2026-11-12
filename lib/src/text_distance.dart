int computeEditDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previous = List.generate(b.length + 1, (i) => i);
  var current = List.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      final substitution = previous[j - 1] + cost;
      current[j] = [
        deletion,
        insertion,
        substitution,
      ].reduce((a, b) => a < b ? a : b);
    }
    final temp = previous;
    previous = current;
    current = temp;
  }

  return previous[b.length];
}
