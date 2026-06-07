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
  List<Vector2>? fromBeachSpawnPoly;
  List<Vector2>? fromHubSpawnPoly;
  List<Vector2>? fromMuseumSpawnPoly;
  final List<BinData> bins = [];
  final List<BinData> welcomeBoards = [];
  Rect? minigameStartZone;
  Rect? toBeachZone;
  Rect? toMuseumZone;
  Rect? toHubZone;

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
      if (objectGroup.name == 'collision' || objectGroup.name == 'collission') {
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
          } else if (tiledObject.type == 'from_beach') {
            fromBeachSpawnPoly = tiledObject.isPolygon
                ? tiledObject.polygon.map((p) => Vector2(tiledObject.x + p.x, tiledObject.y + p.y)).toList()
                : [Vector2(tiledObject.x + tiledObject.width / 2, tiledObject.y + tiledObject.height / 2)];
          } else if (tiledObject.type == 'from_hub') {
            fromHubSpawnPoly = tiledObject.isPolygon
                ? tiledObject.polygon.map((p) => Vector2(tiledObject.x + p.x, tiledObject.y + p.y)).toList()
                : [Vector2(tiledObject.x + tiledObject.width / 2, tiledObject.y + tiledObject.height / 2)];
          } else if (tiledObject.type == 'from_museum') {
            fromMuseumSpawnPoly = tiledObject.isPolygon
                ? tiledObject.polygon.map((p) => Vector2(tiledObject.x + p.x, tiledObject.y + p.y)).toList()
                : [Vector2(tiledObject.x + tiledObject.width / 2, tiledObject.y + tiledObject.height / 2)];
          }
        }
      } else if (objectGroup.name == 'interactible' || objectGroup.name == 'interactibles') {
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
          } else if (tiledObject.type == 'to_beach' || tiledObject.name == 'to beach') {
            toBeachZone = Rect.fromLTWH(
              tiledObject.x, tiledObject.y,
              math.max(tiledObject.width, 1),
              math.max(tiledObject.height, 1),
            );
          } else if (tiledObject.type == 'to_museum' || tiledObject.name == 'to museum') {
            toMuseumZone = Rect.fromLTWH(
              tiledObject.x, tiledObject.y,
              math.max(tiledObject.width, 1),
              math.max(tiledObject.height, 1),
            );
          } else if (tiledObject.type == 'to_hub' || tiledObject.name == 'to hub' || tiledObject.type == 'goto_hub' || tiledObject.name == 'goto hub') {
            toHubZone = Rect.fromLTWH(
              tiledObject.x, tiledObject.y,
              math.max(tiledObject.width, 1),
              math.max(tiledObject.height, 1),
            );
          } else if (tiledObject.type == 'welcome_board' || tiledObject.name == 'welcome board') {
            welcomeBoards.add(BinData(
              tiledObject.name,
              tiledObject.x + tiledObject.width / 2,
              tiledObject.y + tiledObject.height / 2,
              math.max(tiledObject.width, 1),
              math.max(tiledObject.height, 1),
            ));
          }
        }
      }
    }
  }

  @override
  void onRemove() {
    collisionRects.clear();
    collisionPolys.clear();
    welcomeBoards.clear();
    super.onRemove();
  }
}

