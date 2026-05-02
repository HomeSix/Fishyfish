import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'dart:ui' show Image;
import '../utils/animation_helper.dart';

class Player extends SpriteAnimationComponent with CollisionCallbacks {
  final double speed = 200;
  final double characterSize = 100;
  final double characterSpeed = 0.15;
  final Image image;

  late SpriteAnimation downAnimation;
  late SpriteAnimation leftAnimation;
  late SpriteAnimation rightAnimation;
  late SpriteAnimation upAnimation;
  late SpriteAnimation idleAnimation;

  int direction = 0;

  Player(this.image) : super(anchor: Anchor.center);

  Vector2 _previousPosition = Vector2.zero();

  @override
  Future<void> onLoad() async {
    final spriteSheet = SpriteSheet(image: image, srcSize: Vector2(32, 32));

    downAnimation = createColumnAnimation(spriteSheet, 0, 8, characterSpeed);
    leftAnimation = createColumnAnimation(spriteSheet, 1, 8, characterSpeed);
    upAnimation = createColumnAnimation(spriteSheet, 2, 8, characterSpeed);
    rightAnimation = createColumnAnimation(spriteSheet, 3, 8, characterSpeed);
    idleAnimation = createColumnAnimation(spriteSheet, 0, 1, characterSpeed);

    animation = idleAnimation;
    // Start at the front door (in front of the house)
    position = Vector2(256, 340);
    size = Vector2.all(characterSize);

    _previousPosition = position.clone();

    // Enable debug mode to show hitbox
    debugMode = true;

    // Add hitbox for collision detection (smaller, at feet level)
    add(RectangleHitbox(
      position: Vector2(characterSize * 0.3, characterSize * 0.65),
      size: Vector2(characterSize * 0.4, characterSize * 0.3),
    )..collisionType = CollisionType.active);
  }

  void updateMovement(JoystickComponent joystick, double dt, Vector2 gameSize) {
    _previousPosition.setFrom(position);

    if (joystick.direction != JoystickDirection.idle) {
      final delta = joystick.delta;

      if (delta.length > 0) {
        final movement = delta.normalized() * speed * dt;
        position += movement;

        // Fixed angle calculation for screen coordinates
        final angle = math.atan2(delta.y, delta.x);
        final degrees = (angle * 180 / math.pi + 360) % 360;

        if (degrees >= 315 || degrees < 45) {
          animation = rightAnimation;
          direction = 2;
        } else if (degrees >= 45 && degrees < 135) {
          animation = downAnimation;   // Screen down
          direction = 3;
        } else if (degrees >= 135 && degrees < 225) {
          animation = leftAnimation;
          direction = 1;
        } else {
          animation = upAnimation;     // Screen up
          direction = 4;
        }
      }
    } else {
      animation = idleAnimation;
      direction = 0;
    }

    // Keep player in bounds
    position.clamp(
      Vector2(size.x / 2, size.y / 2),
      Vector2(gameSize.x - size.x / 2, gameSize.y - size.y / 2),
    );
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    // Revert to previous position when hitting something
    position.setFrom(_previousPosition);
  }
}