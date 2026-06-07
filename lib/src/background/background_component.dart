import 'dart:math' as math;
import 'dart:ui' show Rect;
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class BinData {
  final String name;
  final double x, y, width, height;
  BinData(this.name, this.x, this.y, this.width, this.height);
}

class BackgroundComponent extends PositionComponent with HasGameReference {
  late TiledComponent map;
  final String mapName;

  final List<Rect> collisionRects = [];
  final List<List<Vector2>> collisionPolys = [];
  List<Vector2>? trashSpawnPoly;
  List<Vector2>? playerSpawnPoly;
  final List<BinData> bins = [];
  Rect? minigameStartZone;

  BackgroundComponent({this.mapName = 'map1'});

  double get _tileSize => 32.0;

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
    for (final objectGroup in map.tileMap.map.layers.whereType<ObjectGroup>()) {
      if (objectGroup.name == 'collision') {
        for (final tiledObject in objectGroup.objects) {
          if (tiledObject.isPolygon) {
            final pts = tiledObject.polygon;
            final world = <Vector2>[];
            for (final p in pts) {
              world.add(Vector2(tiledObject.x + p.x, tiledObject.y + p.y));
            }
            collisionPolys.add(world);
          } else {
            collisionRects.add(Rect.fromLTWH(
              tiledObject.x,
              tiledObject.y,
              math.max(tiledObject.width, 1),
              math.max(tiledObject.height, 1),
            ));
          }
        }
      } else if (objectGroup.name == 'spawn point') {
        for (final tiledObject in objectGroup.objects) {
          if (tiledObject.type == 'trash_spawn' && tiledObject.isPolygon) {
            final pts = tiledObject.polygon;
            final world = <Vector2>[];
            for (final p in pts) {
              world.add(Vector2(tiledObject.x + p.x, tiledObject.y + p.y));
            }
            trashSpawnPoly = world;
          } else if (tiledObject.type == 'player_spawn') {
            if (tiledObject.isPolygon) {
              final pts = tiledObject.polygon;
              final world = <Vector2>[];
              for (final p in pts) {
                world.add(Vector2(tiledObject.x + p.x, tiledObject.y + p.y));
              }
              playerSpawnPoly = world;
            } else {
              playerSpawnPoly = [
                Vector2(tiledObject.x + tiledObject.width / 2, tiledObject.y + tiledObject.height / 2),
              ];
            }
          }
        }
      } else if (objectGroup.name == 'interactible') {
        for (final tiledObject in objectGroup.objects) {
          if (tiledObject.type.endsWith('_bin') || tiledObject.name.endsWith(' bin')) {
            bins.add(BinData(
              tiledObject.name,
              tiledObject.x + tiledObject.width / 2,
              tiledObject.y + tiledObject.height / 2,
              math.max(tiledObject.width, 1),
              math.max(tiledObject.height, 1),
            ));
          } else if (tiledObject.type == 'minigame_start' || tiledObject.name == 'start minigame') {
            minigameStartZone = Rect.fromLTWH(
              tiledObject.x, tiledObject.y,
              math.max(tiledObject.width, 1),
              math.max(tiledObject.height, 1),
            );
          }
        }
      }
    }
  }

  @override
  void onRemove() {
    collisionRects.clear();
    collisionPolys.clear();
    super.onRemove();
  }
}

