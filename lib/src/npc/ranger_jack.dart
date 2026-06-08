import 'dart:ui' show Image;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class RangerJackNPC extends SpriteComponent with CollisionCallbacks {
  final Image npcImage;
  RangerJackNPC(this.npcImage) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = Sprite(npcImage);
    size = Vector2.all(48);
    add(
      RectangleHitbox(
        position: Vector2(size.x * 0.2, size.y * 0.3 - 1),
        size: Vector2(size.x * 0.6, size.y * 0.6 + 2),
      )..collisionType = CollisionType.active,
    );
  }
}
