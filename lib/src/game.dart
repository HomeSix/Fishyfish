import 'package:flame/game.dart';
import 'package:flame/components.dart';

import 'player/player.dart';
import 'onScreen/joystick.dart';
import 'background/background_component.dart';

class FishyFishGame extends FlameGame with HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late BackgroundComponent background;
  String currentMap = 'map1';
  bool showDebugCoordinates = false; // Set to true when placing zones
  
  // Define transition zones
  late PolygonComponent map1ToMap2Zone;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Background/Tilemap - add to the default world
    background = BackgroundComponent(mapName: currentMap);
    await world.add(background);

    final image = await images.load('Apin.png');

    // Player - add to the default world
    player = Player(image);
    await world.add(player);

    // Joystick - add to camera viewport (stays on screen)
    joystick = createJoystick();
    camera.viewport.add(joystick);

    // Camera setup
    camera.viewfinder.anchor = Anchor.center;
    camera.follow(player, maxSpeed: double.infinity);

    // Initialize transition zones
    map1ToMap2Zone = PolygonComponent([
      Vector2(225, 283),
      Vector2(260, 283),
      Vector2(240, 290),
      Vector2(253, 290),
    ]);
  }

  Future<void> changeMap(String newMap, {Vector2? newPosition}) async {
    // Remove old background
    background.removeFromParent();
    
    // Create and add new background
    currentMap = newMap;
    background = BackgroundComponent(mapName: newMap);
    await world.add(background);
    
    // Set player position if provided
    if (newPosition != null) {
      player.position = newPosition;
    }
  }
  

  @override
  void update(double dt) {
    player.updateMovement(joystick, dt, size);
    
    if (showDebugCoordinates) {
      print('Player: ${player.position}');
    }
    
    // Check for map transitions
    if (currentMap == 'map1' && map1ToMap2Zone.containsPoint(player.position)) {
      changeMap('map2', newPosition: Vector2(100, 100)); // Set desired spawn position
    }
    
    super.update(dt);
  }
}