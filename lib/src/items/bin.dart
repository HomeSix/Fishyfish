import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class Bin extends PositionComponent {
  Bin({super.position})
      : super(size: Vector2(48, 64), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      RectangleHitbox(
        position: Vector2(1, 8),
        size: Vector2(46, 54),
        collisionType: CollisionType.passive,
      ),
    );

    priority = position.y.toInt();
  }

  @override
  set position(Vector2 value) {
    super.position = value;
    priority = value.y.toInt();
  }
}
