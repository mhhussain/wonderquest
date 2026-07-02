import 'dart:math';

List<List<T>> dealGames<T>(
    {required List<T> pool,
    required int games,
    required int perGame,
    required Random random}) {
  final use = <T, int>{for (final p in pool) p: 0};
  final out = <List<T>>[];
  for (var g = 0; g < games; g++) {
    final game = <T>[];
    final candidates = [...pool]..shuffle(random);
    candidates.sort((a, b) => use[a]!.compareTo(use[b]!)); // stable: keeps shuffle for ties
    for (final c in candidates) {
      if (game.length == perGame) break;
      game.add(c);
      use[c] = use[c]! + 1;
    }
    var i = 0;
    while (game.length < perGame) {
      game.add(pool[i % pool.length]);
      i++;
    }
    game.shuffle(random);
    out.add(game);
  }
  return out;
}
