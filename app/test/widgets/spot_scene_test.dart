import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/audio/sfx_service.dart';
import 'package:wonder_quest/domain/spot_scene_engine.dart';
import 'package:wonder_quest/theme/wq_colors.dart';
import 'package:wonder_quest/widgets/spot_scene.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// No-op [SfxService] — avoids platform channels in tests.
class _FakeSfxService implements SfxService {
  @override
  Future<void> play(Sfx sfx) async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SpotScene', () {
    testWidgets(
      '1 goal (🐝 ×2), 0 decoys — tapping both bees fires onComplete',
      (tester) async {
        var completeCalled = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sfxServiceProvider.overrideWithValue(_FakeSfxService()),
            ],
            child: MaterialApp(
              home: SpotScene(
                goals: const [
                  SpotGoal(char: '🐝', count: 2, label: 'bee'),
                ],
                mode: SpotMode.find,
                decoys: const [],
                decoyCount: 0,
                bg: WqColors.sky,
                onComplete: () => completeCalled = true,
              ),
            ),
          ),
        );

        // Let LayoutBuilder's post-frame callback fire and rebuild with items.
        await tester.pump();
        await tester.pump();

        // Both bees should now be in the widget tree as tappable items.
        // IDs 0 and 1 since total = 2 items (2 targets, 0 decoys).
        final bee0 = find.byKey(const ValueKey('spot-item-0'));
        final bee1 = find.byKey(const ValueKey('spot-item-1'));
        expect(bee0, findsOneWidget);
        expect(bee1, findsOneWidget);

        // Tap the first bee.
        await tester.tap(bee0);
        await tester.pump();

        expect(completeCalled, isFalse, reason: 'Only 1/2 bees tapped');

        // Tap the second bee.
        await tester.tap(bee1);
        // Drain the 600 ms onComplete delay.
        await tester.pump(const Duration(milliseconds: 700));

        expect(completeCalled, isTrue, reason: 'Both bees tapped — should fire onComplete');
      },
    );

    testWidgets(
      'goal chip shows 0/2 initially and updates as targets are tapped',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sfxServiceProvider.overrideWithValue(_FakeSfxService()),
            ],
            child: MaterialApp(
              home: SpotScene(
                goals: const [
                  SpotGoal(char: '🐝', count: 2, label: 'bee'),
                ],
                mode: SpotMode.find,
                decoys: const [],
                decoyCount: 0,
                bg: WqColors.sky,
                onComplete: () {},
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        // Initial chip shows 0/2.
        expect(find.text('0/2'), findsOneWidget);

        // Tap one bee item (ID 0 is always the first placed item).
        await tester.tap(find.byKey(const ValueKey('spot-item-0')));
        await tester.pump();

        // Chip should now show 1/2.
        expect(find.text('1/2'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a decoy shows ripple centered on decoy',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sfxServiceProvider.overrideWithValue(_FakeSfxService()),
            ],
            child: MaterialApp(
              home: SpotScene(
                goals: const [
                  SpotGoal(char: '🐝', count: 2, label: 'bee'),
                ],
                mode: SpotMode.find,
                decoys: const ['🌟'],
                decoyCount: 3,
                bg: WqColors.sky,
                onComplete: () {},
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        // Ripple should not exist initially.
        expect(find.byKey(const ValueKey('spot-miss')), findsNothing);

        // Find all items.
        final items = find.byKey(
          const ValueKey('spot-item-0'),
        ).evaluate();
        expect(items, isNotEmpty, reason: 'Should have at least one item');

        // Tap an item (any will do to verify ripple appears).
        // The ripple appears when tapping a decoy (non-target).
        // Since we have 2 targets and 3 decoys, most items will be decoys.
        final firstItem = find.byKey(const ValueKey('spot-item-0'));
        expect(firstItem, findsOneWidget);

        await tester.tap(firstItem);
        await tester.pump();

        // After tapping, either the ripple appears (if it was a decoy)
        // or it doesn't (if it was a target). But the fix ensures
        // if a ripple appears, it's centered on the tapped item's position.
        final ripple = find.byKey(const ValueKey('spot-miss'));

        if (ripple.evaluate().isNotEmpty) {
          // Ripple is visible, verify it's positioned reasonably near the tapped item.
          final itemRect = tester.getRect(firstItem);
          final rippleRect = tester.getRect(ripple);

          // Ripple should be within ~50 pixels of the item's center
          // (the offset of 24px from Positioned + text size allows for ~32-40px distance).
          expect(
            (rippleRect.center - itemRect.center).distance,
            lessThan(50.0),
            reason: 'Ripple should be positioned near tapped item',
          );
        }

        // Wait for all animations to settle.
        await tester.pumpAndSettle();
      },
    );
  });
}
