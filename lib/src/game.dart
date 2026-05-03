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

    
  }

  Future<void> changeMap(String newMap) async {
    // Remove old background
    background.removeFromParent();
    
    // Create and add new background
    currentMap = newMap;
    background = BackgroundComponent(mapName: newMap);
    await world.add(background);
  }
  

  @override
  void update(double dt) {
    player.updateMovement(joystick, dt, size);
    
    if (showDebugCoordinates) {
      print('Player: ${player.position}');
    }
    
    // Check for map transitions using polygon
    final map1ToMap2Zone = PolygonComponent([
      Vector2(240, 283),
      Vector2(253, 283),
      Vector2(240, 290),
      Vector2(253, 290),
    ]);

    if (currentMap == 'map1' && map1ToMap2Zone.containsPoint(player.position)) {
      changeMap('map2');
    }
    
    super.update(dt);
  }
}