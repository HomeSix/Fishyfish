import 'package:flame/game.dart';
import 'package:flame/components.dart';

import 'player/player.dart';
import 'onScreen/joystick.dart';
import 'background/background_component.dart';

class FishyFishGame extends FlameGame with HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late BackgroundComponent background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Background/Tilemap - add to the default world
    background = BackgroundComponent();
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
  

  @override
  void update(double dt) {
    player.updateMovement(joystick, dt, size);
    super.update(dt);
  }
}