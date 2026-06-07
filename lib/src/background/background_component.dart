import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tiled/tiled.dart' as tiled;

class BackgroundComponent extends PositionComponent with HasGameReference {
  late TiledComponent map;
  final List<RectangleHitbox> collisionBlocks = [];
  final String mapName;

  BackgroundComponent({this.mapName = 'map1'});

  double get _tileSize {
    switch (mapName) {
      case 'map1':
        return 64.0;
      case 'map2':
      case 'house':
        return 16.0;
      case 'beach':
      case 'museum':
      default:
        return 32.0;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      map = await TiledComponent.load('$mapName/map.tmx', Vector2.all(_tileSize));
    } catch (_) {
      map = await TiledComponent.load('$mapName.tmx', Vector2.all(_tileSize));
    }
    await add(map);

    _setupCollision();
  }

  void _setupCollision() {
    final layers = map.tileMap.map.layers;

    for (final layer in layers) {
      if (layer is! tiled.TileLayer) continue;

      final hasCollider = layer.properties.any(
        (p) => p.name == 'collider' && p.value == true,
      );
      if (!hasCollider) continue;

      final tileData = layer.tileData;
      if (tileData == null) continue;

      final tileWidth = map.tileMap.map.tileWidth.toDouble();
      final tileHeight = map.tileMap.map.tileHeight.toDouble();

     for (var y = 0; y < tileData.length; y++) {
        for (var x = 0; x < tileData[y].length; x++) {
          final gid = tileData[y][x];
          final rawGid = gid.tile; // Extract raw int
          const allFlipFlags = 0xE0000000;
          final cleanGid = rawGid & ~allFlipFlags;
          if (cleanGid == 0) continue;

          final hitbox = RectangleHitbox(
            position: Vector2(x * tileWidth, y * tileHeight),
            size: Vector2(tileWidth, tileHeight),
          )..collisionType = CollisionType.passive;

          collisionBlocks.add(hitbox);
          add(hitbox);
        }
      }
    }
  }

  List<RectangleHitbox> getCollisions() => List.unmodifiable(collisionBlocks);

  @override
  void onRemove() {
    for (final hitbox in collisionBlocks) {
      hitbox.removeFromParent();
    }
    collisionBlocks.clear();
    super.onRemove();
  }
}

