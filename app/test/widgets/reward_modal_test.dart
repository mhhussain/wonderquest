import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/audio/sfx_service.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/domain/reward.dart';
import 'package:wonder_quest/widgets/reward_modal.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// In-memory [SaveFileStore] (same pattern as hud_test.dart).
/// Uses [Future.value] so all I/O resolves in microtask queue, compatible
/// with testWidgets' FakeAsync zone.
class _MemStore extends SaveFileStore {
  _MemStore() : super(Directory.systemTemp);

  SaveData? _seeded;

  @override
  Future<SaveData> load() =>
      Future.value(_seeded ?? SaveData.initial(profileId: 'mem'));

  @override
  Future<void> save(SaveData data) async => _seeded = data;
}

/// No-op [SfxService] — avoids platform channels in tests.
class _FakeSfxService implements SfxService {
  @override
  Future<void> play(Sfx sfx) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal [ProviderScope] + [MaterialApp] with a trigger button
/// that calls [showRewardModal] when tapped.
Widget _buildHarness({
  required _MemStore store,
  required Reward reward,
  VoidCallback? onPlayAgain,
}) {
  return ProviderScope(
    overrides: [
      saveStoreProvider.overrideWithValue(store),
      sfxServiceProvider.overrideWithValue(_FakeSfxService()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => ElevatedButton(
            key: const Key('trigger'),
            onPressed: () {
              showRewardModal(
                context,
                ref,
                reward,
                onPlayAgain: onPlayAgain,
              );
            },
            child: const Text('Go'),
          ),
        ),
      ),
    ),
  );
}

/// Pumps enough frames to resolve [AsyncNotifier.build] (microtask-based).
Future<void> _settleProvider(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Pumps enough frames to complete [SaveController.apply] + open the dialog.
Future<void> _settleAfterTap(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('showRewardModal', () {
    testWidgets(
      'renders +3 and +40 XP texts and increases stars by 3',
      (tester) async {
        final store = _MemStore();

        await tester.pumpWidget(
          _buildHarness(
            store: store,
            reward: const Reward(stars: 3, xp: 40),
          ),
        );
        await _settleProvider(tester);

        // Open the modal.
        await tester.tap(find.byKey(const Key('trigger')));
        await _settleAfterTap(tester);

        // Dialog content assertions.
        expect(find.text('+3'), findsOneWidget);
        expect(find.text('+40 XP'), findsOneWidget);

        // Provider state: stars should be 3.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Consumer)),
        );
        expect(
          container.read(saveControllerProvider).requireValue.stars,
          equals(3),
        );
      },
    );

    testWidgets(
      'silent reward applies reward but shows no dialog',
      (tester) async {
        final store = _MemStore();

        await tester.pumpWidget(
          _buildHarness(
            store: store,
            reward: const Reward(stars: 5, silent: true),
          ),
        );
        await _settleProvider(tester);

        // Tap trigger (will call showRewardModal with silent reward).
        await tester.tap(find.byKey(const Key('trigger')));
        await _settleAfterTap(tester);

        // No dialog should appear.
        expect(find.byType(Dialog), findsNothing);

        // Reward was still applied: stars = 5.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Consumer)),
        );
        expect(
          container.read(saveControllerProvider).requireValue.stars,
          equals(5),
        );
      },
    );

    testWidgets(
      'Play again button calls onPlayAgain callback',
      (tester) async {
        final store = _MemStore();
        var playAgainCalled = false;

        await tester.pumpWidget(
          _buildHarness(
            store: store,
            reward: const Reward(stars: 1, xp: 10),
            onPlayAgain: () => playAgainCalled = true,
          ),
        );
        await _settleProvider(tester);

        await tester.tap(find.byKey(const Key('trigger')));
        await _settleAfterTap(tester);

        // Both buttons visible.
        expect(find.byKey(const Key('reward-map')), findsOneWidget);
        expect(find.byKey(const Key('reward-play-again')), findsOneWidget);

        // Tap play again.
        await tester.tap(find.byKey(const Key('reward-play-again')));
        await tester.pump();
        await tester.pump();

        expect(playAgainCalled, isTrue);
      },
    );

    testWidgets(
      'Play again button hidden when onPlayAgain is null',
      (tester) async {
        final store = _MemStore();

        await tester.pumpWidget(
          _buildHarness(
            store: store,
            reward: const Reward(stars: 1, xp: 10),
          ),
        );
        await _settleProvider(tester);

        await tester.tap(find.byKey(const Key('trigger')));
        await _settleAfterTap(tester);

        expect(find.byKey(const Key('reward-map')), findsOneWidget);
        expect(find.byKey(const Key('reward-play-again')), findsNothing);
      },
    );
  });
}
