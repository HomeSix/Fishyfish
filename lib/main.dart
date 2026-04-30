import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;

void main() {
  runApp(
    GameWidget(game: MyGame()),
  );
}

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    world.add(Player(position: Vector2(0, 0)));
  }
}

class Player extends PositionComponent {
  Player({required Vector2 position}) : super(position: position, size: Vector2(50, 50));

  @override
  Future<void> onLoad() async {
    // Player initialization here
  }

  @override
  void render(Canvas canvas) {
    // Draw a red square
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color.fromARGB(255, 255, 255, 255),
    );
  }
}