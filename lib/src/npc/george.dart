import 'dart:ui' show Image;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class GeorgeNPC extends SpriteComponent with CollisionCallbacks {
  final Image npcImage;
  GeorgeNPC(this.npcImage) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Tile [row=1, col=1] (1-indexed) = (0, 0) in 0-indexed = downwards facing
    // Image is 4x4 grid of 48x48 tiles (192x192 total)
    sprite = Sprite(
      npcImage,
      srcPosition: Vector2(0, 0),
      srcSize: Vector2(48, 48),
    );
    // Change this Vector2.all value to resize George (80 = current, 100 = player size)
    size = Vector2.all(80);
    position = Vector2(448, 270);
    add(
      RectangleHitbox(
        position: Vector2(size.x * 0.2, size.y * 0.2),
        size: Vector2(size.x * 0.6, size.y * 0.6),
      )..collisionType = CollisionType.passive,
    );
    debugMode = true;
  }
}
