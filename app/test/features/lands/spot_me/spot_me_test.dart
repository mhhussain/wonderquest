import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/spot_scenes_content.dart';
import 'package:wonder_quest/domain/spot_scene_engine.dart';
import 'package:wonder_quest/features/lands/spot_me/detective_game.dart';
import 'package:wonder_quest/features/lands/spot_me/socks_game.dart';
import 'package:wonder_quest/features/lands/spot_me/spot_difference_game.dart';

void main() {
  // ── Spot the Difference ───────────────────────────────────────────────────

  group('generateDiff', () {
    // Build a predictable base scene with 5 items.
    final baseItems = List.generate(
      5,
      (i) => PlacedItem(
        char: '🌿',
        pos: Offset(i * 80.0, 50),
        size: 48,
        isTarget: false,
        id: i,
      ),
    );

    test('produces exactly one differing item between scene A and scene B', () {
      final result = generateDiff(
        base: baseItems,
        swapChar: '🐠',
        random: Random(42),
      );

      // Count items whose char differs between A and B (matching by id).
      final aById = {for (final item in result.sceneA) item.id: item};
      final bById = {for (final item in result.sceneB) item.id: item};

      final diffs = aById.entries
          .where((e) => bById[e.key]?.char != e.value.char)
          .toList();

      expect(
        diffs.length,
        equals(1),
        reason: 'Exactly one item should differ between scene A and scene B',
      );
    });

    test('changed item in B has the swap char', () {
      final result = generateDiff(
        base: baseItems,
        swapChar: '🐠',
        random: Random(42),
      );

      final changedInB =
          result.sceneB.firstWhere((item) => item.id == result.changedId);
      expect(changedInB.char, equals('🐠'));
    });

    test('all other items in B are unchanged', () {
      final result = generateDiff(
        base: baseItems,
        swapChar: '🐠',
        random: Random(42),
      );

      final aById = {for (final item in result.sceneA) item.id: item};

      for (final bItem in result.sceneB) {
        if (bItem.id == result.changedId) continue;
        expect(
          bItem.char,
          equals(aById[bItem.id]!.char),
          reason: 'Item ${bItem.id} should be unchanged in scene B',
        );
      }
    });

    test('changed item is marked isTarget=true in B', () {
      final result = generateDiff(
        base: baseItems,
        swapChar: '🐠',
        random: Random(42),
      );

      final changedInB =
          result.sceneB.firstWhere((item) => item.id == result.changedId);
      expect(changedInB.isTarget, isTrue);
    });

    test('scene A and B have the same number of items', () {
      final result = generateDiff(
        base: baseItems,
        swapChar: '🐠',
        random: Random(42),
      );
      expect(result.sceneA.length, equals(result.sceneB.length));
    });
  });

  // ── Detective config — no false positives in decoy pool ───────────────────

  group('Detective config', () {
    void checkNoFalsePositives(List<DetectiveRound> rounds, String gameTitle) {
      for (final round in rounds) {
        expect(
          round.pool.contains(round.target),
          isFalse,
          reason: '$gameTitle round "${round.label}": target '
              '"${round.target}" must not appear in its own decoy pool',
        );
        expect(
          round.n,
          greaterThanOrEqualTo(1),
          reason: '$gameTitle round "${round.label}": must have ≥1 target',
        );
      }
    }

    test('Letter Detective rounds: target not in decoy pool', () {
      checkNoFalsePositives(kLetterRounds, 'Letter Detective');
    });

    test('Number Detective rounds: target not in decoy pool', () {
      checkNoFalsePositives(kNumberRounds, 'Number Detective');
    });

    test('Shape Safari rounds: target not in decoy pool', () {
      checkNoFalsePositives(kShapeRounds, 'Shape Safari');
    });

    test('all detective round scenes exist in kSceneMap', () {
      final allRounds = [...kLetterRounds, ...kNumberRounds, ...kShapeRounds];
      for (final round in allRounds) {
        expect(
          kSceneMap.containsKey(round.sceneKey),
          isTrue,
          reason: 'Scene "${round.sceneKey}" not found in kSceneMap',
        );
      }
    });

    test('SingleFindScreen config has non-empty rounds', () {
      // Smoke-test the configs used by concrete screens.
      const configs = [
        DetectiveConfig(
          rounds: kLetterRounds,
          title: 'Letter Detective',
          emoji: '🔤',
          color: Color(0xFFFF8A3D),
          sticker: '🔤',
          xp: 28,
          progressTo: 55,
        ),
        DetectiveConfig(
          rounds: kNumberRounds,
          title: 'Number Detective',
          emoji: '🕵️',
          color: Color(0xFF4AA8E0),
          sticker: '🔢',
          xp: 28,
          progressTo: 50,
        ),
        DetectiveConfig(
          rounds: kShapeRounds,
          title: 'Shape Safari',
          emoji: '🔺',
          color: Color(0xFF8B7BE0),
          sticker: '🔺',
          xp: 26,
          progressTo: 50,
        ),
      ];

      for (final cfg in configs) {
        expect(
          cfg.rounds.isNotEmpty,
          isTrue,
          reason: '${cfg.title} config must have at least one round',
        );
      }
    });
  });

  // ── Match-the-Socks: level criteria ───────────────────────────────────────

  group('socksMatch', () {
    const red = Color(0xFFE84B4B);
    const blue = Color(0xFF3F86D6);

    const redSolid = SockItem(
      pairId: 0,
      color: red,
      pattern: 'solid',
      slotIndex: 0,
    );
    const blueSolid = SockItem(
      pairId: 1,
      color: blue,
      pattern: 'solid',
      slotIndex: 1,
    );
    const redStripe = SockItem(
      pairId: 2,
      color: red,
      pattern: 'stripe',
      slotIndex: 2,
    );
    const blueStripe = SockItem(
      pairId: 3,
      color: blue,
      pattern: 'stripe',
      slotIndex: 3,
    );

    const levelColor = SockLevel(pairs: 4, by: 'color', say: '');
    const levelPattern = SockLevel(pairs: 5, by: 'pattern', say: '');
    const levelBoth = SockLevel(pairs: 6, by: 'both', say: '');

    // Level 0 — color
    test('level 0 (color): same color matches regardless of pattern', () {
      expect(socksMatch(redSolid, redStripe, levelColor), isTrue);
    });

    test('level 0 (color): different color does not match', () {
      expect(socksMatch(redSolid, blueSolid, levelColor), isFalse);
    });

    // Level 1 — pattern
    test('level 1 (pattern): same pattern matches regardless of color', () {
      expect(socksMatch(redStripe, blueStripe, levelPattern), isTrue);
    });

    test('level 1 (pattern): different pattern does not match', () {
      expect(socksMatch(redSolid, redStripe, levelPattern), isFalse);
    });

    // Level 2 — both (the key behavioral requirement)
    test(
      'level 3 (both): requires same color AND same pattern',
      () {
        // Same color, same pattern → match.
        expect(socksMatch(redSolid, redSolid, levelBoth), isTrue);

        // Same color, different pattern → no match.
        expect(
          socksMatch(redSolid, redStripe, levelBoth),
          isFalse,
          reason: 'Different pattern must not match on level "both"',
        );

        // Different color, same pattern → no match.
        expect(
          socksMatch(redStripe, blueStripe, levelBoth),
          isFalse,
          reason: 'Different color must not match on level "both"',
        );

        // Different color, different pattern → no match.
        expect(
          socksMatch(redSolid, blueStripe, levelBoth),
          isFalse,
        );
      },
    );

    // generateSocks integrity checks
    test('generateSocks produces the correct number of items (level 0)', () {
      final socks = generateSocks(kSockLevels[0], Random(1));
      expect(socks.length, equals(kSockLevels[0].pairs * 2));
    });

    test('generateSocks produces the correct number of items (level 2)', () {
      final socks = generateSocks(kSockLevels[2], Random(1));
      expect(socks.length, equals(kSockLevels[2].pairs * 2));
    });

    test('generateSocks level 2: each pair matches on both criteria', () {
      final socks = generateSocks(kSockLevels[2], Random(42));
      // Group by pairId.
      final byPair = <int, List<SockItem>>{};
      for (final s in socks) {
        byPair.putIfAbsent(s.pairId, () => []).add(s);
      }

      for (final pair in byPair.values) {
        expect(pair.length, equals(2));
        expect(
          socksMatch(pair[0], pair[1], kSockLevels[2]),
          isTrue,
          reason: 'Pair ${pair[0].pairId} must match on level "both"',
        );
      }
    });

    test('generateSocks level 2: no two different pairs match', () {
      final socks = generateSocks(kSockLevels[2], Random(42));
      // Pick one sock from each pair and check no cross-pair matches.
      final byPair = <int, SockItem>{};
      for (final s in socks) {
        byPair.putIfAbsent(s.pairId, () => s);
      }
      final entries = byPair.values.toList();

      for (var i = 0; i < entries.length; i++) {
        for (var j = i + 1; j < entries.length; j++) {
          // Two different pairs must NOT match on level "both".
          expect(
            socksMatch(entries[i], entries[j], kSockLevels[2]),
            isFalse,
            reason: 'Pairs ${entries[i].pairId} and ${entries[j].pairId} '
                'must not cross-match on level "both"',
          );
        }
      }
    });
  });
}
