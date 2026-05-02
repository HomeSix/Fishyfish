// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_topics_game/main.dart';
import 'package:special_topics_game/src/game.dart';

void main() {
  testWidgets('Flame game initializes', (WidgetTester tester) async {
    // Build our game and trigger a frame.
    await tester.pumpWidget(
      GameWidget(game: FishyFishGame()),
    );

    // Verify the GameWidget renders without errors
    expect(find.byType(GameWidget), findsOneWidget);
  });
}
