import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class Bin extends PositionComponent {
  Bin({super.position})
      : super(size: Vector2(48, 64), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    debugMode = true;

    add(
      RectangleHitbox(
        position: Vector2(1, 8),
        size: Vector2(46, 54),
        collisionType: CollisionType.passive,
      ),
    );

    final body = RectangleComponent(
      size: Vector2(40, 46),
      position: Vector2(4, 16),
      paint: Paint()..color = const Color(0xFF37474F),
    );
    add(body);

    final rim = RectangleComponent(
      size: Vector2(46, 8),
      position: Vector2(1, 8),
      paint: Paint()..color = const Color(0xFF546E7A),
    );
    add(rim);

    final lid = RectangleComponent(
      size: Vector2(30, 4),
      position: Vector2(9, 14),
      paint: Paint()..color = const Color(0xFF455A64),
    );
    add(lid);

    priority = position.y.toInt();
  }

  @override
  set position(Vector2 value) {
    super.position = value;
    priority = value.y.toInt();
  }
}
