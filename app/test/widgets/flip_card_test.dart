import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/widgets/flip_card.dart';

void main() {
  group('FlipCard', () {
    testWidgets(
      'front is visible initially, back is not',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FlipCard(
                front: Text('Front', key: Key('front')),
                back: Text('Back', key: Key('back')),
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('front')), findsOneWidget);
        expect(find.byKey(const Key('back')), findsNothing);
      },
    );

    testWidgets(
      'startFlipped=true shows back initially',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FlipCard(
                front: Text('Front', key: Key('front')),
                back: Text('Back', key: Key('back')),
                startFlipped: true,
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('front')), findsNothing);
        expect(find.byKey(const Key('back')), findsOneWidget);
      },
    );

    testWidgets(
      'tap toggles flip and onFlipped fires once',
      (tester) async {
        var flipCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlipCard(
                front: const Text('Front', key: Key('front')),
                back: const Text('Back', key: Key('back')),
                onFlipped: () => flipCount++,
              ),
            ),
          ),
        );

        // Front visible initially.
        expect(find.byKey(const Key('front')), findsOneWidget);
        expect(find.byKey(const Key('back')), findsNothing);

        // Tap to flip.
        await tester.tap(find.byType(FlipCard));
        await tester.pumpAndSettle();

        // Back now visible.
        expect(find.byKey(const Key('front')), findsNothing);
        expect(find.byKey(const Key('back')), findsOneWidget);

        // onFlipped called once.
        expect(flipCount, equals(1));

        // Tap again to flip back.
        await tester.tap(find.byType(FlipCard));
        await tester.pumpAndSettle();

        // Front visible again.
        expect(find.byKey(const Key('front')), findsOneWidget);
        expect(find.byKey(const Key('back')), findsNothing);

        // onFlipped still called only once (no second call on flip back).
        expect(flipCount, equals(1));
      },
    );

    testWidgets(
      'without onFlipped callback, flip still works',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FlipCard(
                front: Text('Front', key: Key('front')),
                back: Text('Back', key: Key('back')),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(FlipCard));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('back')), findsOneWidget);
      },
    );
  });
}
