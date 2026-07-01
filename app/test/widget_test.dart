import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/app.dart';

void main() {
  testWidgets('app boots and shows Wonder Quest title', (tester) async {
    await tester.pumpWidget(const WonderQuestApp());
    expect(find.text('Wonder Quest'), findsOneWidget);
  });

  testWidgets('placeholder home shows TTS spike debug button', (tester) async {
    await tester.pumpWidget(const WonderQuestApp());
    expect(find.text('Arabic TTS Spike (Task 3)'), findsOneWidget);
  });
}
