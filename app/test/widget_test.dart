import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/app.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const WonderQuestApp());
    expect(find.text('Wonder Quest'), findsOneWidget);
  });
}
