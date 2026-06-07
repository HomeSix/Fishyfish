import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'dart:ui' show Image;
import '../utils/animation_helper.dart';

class Player extends SpriteAnimationComponent {
  final double speed = 200;
  final double characterSize = 65;
  final double characterSpeed = 0.15;
  final Image image;
  late SpriteAnimation downAnimation;
  late SpriteAnimation leftAnimation;
  late SpriteAnimation rightAnimation;
  late SpriteAnimation upAnimation;
  late SpriteAnimation idleDownAnimation;
  late SpriteAnimation idleLeftAnimation;
  late SpriteAnimation idleRightAnimation;
  late SpriteAnimation idleUpAnimation;
  int direction = 3;
  int _lastDirection = 3;
  bool canMove = true;
  Player(this.image) : super(anchor: Anchor.center);
  Vector2 _previousPosition = Vector2.zero();
  Vector2 _intendedMovement = Vector2.zero();

  @override
  Future<void> onLoad() async {
    final spriteSheet = SpriteSheet(image: image, srcSize: Vector2(32, 32));
    downAnimation = createColumnAnimation(spriteSheet, 0, 8, characterSpeed);
    leftAnimation = createColumnAnimation(spriteSheet, 1, 8, characterSpeed);
    upAnimation = createColumnAnimation(spriteSheet, 2, 8, characterSpeed);
    rightAnimation = createColumnAnimation(spriteSheet, 3, 8, characterSpeed);
    idleDownAnimation = createColumnAnimation(spriteSheet, 0, 1, characterSpeed);
    idleLeftAnimation = createColumnAnimation(spriteSheet, 1, 1, characterSpeed);
    idleUpAnimation = createColumnAnimation(spriteSheet, 2, 1, characterSpeed);
    idleRightAnimation = createColumnAnimation(spriteSheet, 3, 1, characterSpeed);
    animation = idleDownAnimation;
    size = Vector2.all(characterSize);
    _previousPosition = position.clone();
  }

  void updateMovement(JoystickComponent joystick, double dt, Vector2 gameSize) {
    if (!canMove) return;
    _previousPosition.setFrom(position);
    _intendedMovement.setZero();

    if (joystick.direction != JoystickDirection.idle) {
      final delta = joystick.delta;
      if (delta.length > 0) {
        _intendedMovement = delta.normalized() * speed * dt;
        position.x += _intendedMovement.x;
        position.y += _intendedMovement.y;
        final angle = math.atan2(delta.y, delta.x);
        final degrees = (angle * 180 / math.pi + 360) % 360;
        if (degrees >= 315 || degrees < 45) {
          animation = rightAnimation;
          direction = 2;
        } else if (degrees >= 45 && degrees < 135) {
          animation = downAnimation;
          direction = 3;
        } else if (degrees >= 135 && degrees < 225) {
          animation = leftAnimation;
          direction = 1;
        } else {
          animation = upAnimation;
          direction = 4;
        }
        _lastDirection = direction;
      } else {
        _setIdleAnimation(_lastDirection);
      }
    } else {
      _setIdleAnimation(_lastDirection);
    }
  }

  void _setIdleAnimation(int facingDirection) {
    direction = facingDirection;

    switch (facingDirection) {
      case 1:
        animation = idleLeftAnimation;
        break;
      case 2:
        animation = idleRightAnimation;
        break;
      case 4:
        animation = idleUpAnimation;
        break;
      case 3:
      default:
        animation = idleDownAnimation;
        break;
    }
  }
}
