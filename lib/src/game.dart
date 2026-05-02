import 'package:flame/game.dart';
import 'package:flame/components.dart';

import '../src/player/player.dart';
import '../src/joystick/joystick.dart';
import '../src/background/background_component.dart';

class FishyFishGame extends FlameGame with HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late BackgroundComponent background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Background/Tilemap
    background = BackgroundComponent();
    await add(background);

    final image = await images.load('Apin.png');

    // Player
    player = Player(image);
    await add(player);

    // Joystick
    joystick = createJoystick();
    add(joystick);

    // Camera
    camera.viewfinder.anchor = Anchor.center;
    camera.follow(player);
  }

  @override
  void update(double dt) {
    super.update(dt);

    player.updateMovement(joystick, dt, size);
  }
}