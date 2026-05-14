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
  late Vector2 _gameSize;
  bool _collidingX = false;
  bool _collidingY = false;
  Vector2 _intendedMovement = Vector2.zero();
  late RectangleHitbox _playerHitbox;

  @override
  Future<void> onLoad() async {
    final spriteSheet = SpriteSheet(image: image, srcSize: Vector2(32, 32));
    downAnimation = createColumnAnimation(spriteSheet, 0, 8, characterSpeed);
    leftAnimation = createColumnAnimation(spriteSheet, 1, 8, characterSpeed);
    upAnimation = createColumnAnimation(spriteSheet, 2, 8, characterSpeed);
    rightAnimation = createColumnAnimation(spriteSheet, 3, 8, characterSpeed);
    idleAnimation = createColumnAnimation(spriteSheet, 0, 1, characterSpeed);
    animation = idleAnimation;
    position = Vector2(256, 340);
    size = Vector2.all(characterSize);
    _previousPosition = position.clone();
    // To see hitboxes of player and collission boxes
    // debugMode = true;
    _playerHitbox = RectangleHitbox(
      position: Vector2(characterSize * 0.35, characterSize * 0.50),
      size: Vector2(characterSize * 0.3, characterSize * 0.25),
    )..collisionType = CollisionType.active;
    add(_playerHitbox);
  }

  void updateMovement(JoystickComponent joystick, double dt, Vector2 gameSize) {
    _previousPosition.setFrom(position);
    _gameSize = gameSize;
    _collidingX = false;
    _collidingY = false;
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
      }
    } else {
      animation = idleAnimation;
      direction = 0;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (intersectionPoints.isEmpty) return;
    final collisionPoint = intersectionPoints.reduce((a, b) => a + b)
      ..scale(1 / intersectionPoints.length);
    final hitboxCenter = Vector2(
      position.x - size.x / 2 + _playerHitbox.position.x + _playerHitbox.size.x / 2,
      position.y - size.y / 2 + _playerHitbox.position.y + _playerHitbox.size.y / 2,
    );
    final toCollision = collisionPoint - hitboxCenter;
    final absX = toCollision.x.abs();
    final absY = toCollision.y.abs();
    if (absX > absY) {
      if (!_collidingX) {
        _collidingX = true;
        position.x = _previousPosition.x;
      }
    } else {
      if (!_collidingY) {
        _collidingY = true;
        position.y = _previousPosition.y;
      }
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    _collidingX = false;
    _collidingY = false;
  }
}
