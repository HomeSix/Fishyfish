import 'package:flame/components.dart';
import 'package:flame/camera.dart';
import 'dart:ui' show Image;
import 'player/player.dart';
import 'background/background_component.dart';
import 'onScreen/joystick.dart';

class GameWorld extends World {
  final Image playerImage;
  
  late Player player;
  late BackgroundComponent background;

  GameWorld({required this.playerImage});

  @override
  Future<void> onLoad() async {
    // Background/Tilemap
    background = BackgroundComponent();
    await add(background);

    // Player
    player = Player(playerImage);
    player.position = Vector2(2056, 1000);
    await add(player);
  }
}
