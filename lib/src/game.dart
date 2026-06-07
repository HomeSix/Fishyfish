import 'dart:async' as async;
import 'dart:math' as math;
import 'dart:ui' show Image, FontWeight, Color, Offset, Shadow;
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/text.dart';

import 'player/player.dart';
import 'onScreen/joystick.dart';
import 'background/background_component.dart';
import 'npc/george.dart';
import 'items/banana_peel.dart';
import 'items/bin.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui show instantiateImageCodec;
import 'onScreen/interact_button.dart';
import 'ui/dialogue_box.dart';
import 'onScreen/inventory_button.dart';
import 'utils/save_manager.dart';

class FishyFishGame extends FlameGame with HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late BackgroundComponent background;
  late GeorgeNPC george;
  late InteractButton interactButton;
  late InventoryButton inventoryButton;
  late DialogueBox dialogueBox;
  late Image _georgeImage;
  late Image _bananaImage;
  BananaPeel? banana;
  SpriteComponent? heldItem;
  final Map<PositionComponent, _InteractionTarget> _itemTargets = {};
  String currentMap = 'beach';
  bool showDebugCoordinates = false; // Set to true when placing zones
  bool _hudReady = false;
  async.Timer? _autoSaveTimer;
  late TextComponent _saveIndicator;
  bool _isSaving = false;
  final List<_InteractionTarget> _interactionTargets = [];

  // Inventory system
  List<String> inventory = ["test item", "mavinesh"];
  void addItemToInventory(String item) {
    inventory.add(item);
  }

  // Define transition zones
  late PolygonComponent map1ToMap2Zone;
  late PolygonComponent houseDoorZone;
  late PolygonComponent houseExitZone;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Background/Tilemap - add to the default world
    background = BackgroundComponent(mapName: currentMap);
    background.priority = -1;
    await world.add(background);

    final image = await images.load('Apin.png');

    // Player - add to the default world
    player = Player(image);
    await world.add(player);

    // George NPC - add to the default world
    _georgeImage = await images.load('george.png');
    george = GeorgeNPC(_georgeImage);
    await world.add(george);
    _interactionTargets.add(
      _InteractionTarget(
        position: () => george.position,
        range: 50,
        label: 'talk',
        onInteract: () {
          dialogueBox.show('George', 'Do you know? Hafiz is gay');
        },
      ),
    );

    // Banana peel item - load and place on the map
    final data = await rootBundle.load('assets/trash/bananaPeel.png');
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    _bananaImage = frame.image;
    banana = BananaPeel(
      sprite: Sprite(_bananaImage),
      size: Vector2(48, 48),
      position: Vector2(300, 680),
    );
    await world.add(banana!);
    final bananaTarget = _InteractionTarget(
      position: () => banana!.position,
      range: 50,
      label: 'pick up',
      onInteract: () {
        _pickupItem(banana!);
      },
    );
    _interactionTargets.add(bananaTarget);
    _itemTargets[banana!] = bananaTarget;

    // Scatter remaining trash assets across the map
    await _scatterTrash();

    // Place a bin 5 tiles (320px) right of the player start position
    await _placeBinNearPlayer();

    // Load saved game data and restore player state
    await _loadGameData();

    // Joystick - add to camera viewport (stays on screen)
    joystick = createJoystick();
    camera.viewport.add(joystick);

    // Interact button - right side of screen
    interactButton = InteractButton(
      onTap: _handleInteract,
    );
    camera.viewport.add(interactButton);

    inventoryButton = InventoryButton(
      onTap: () {
        overlays.add('InventoryOverlay');
      },
    );
    camera.viewport.add(inventoryButton);

    _hudReady = true;
    _updateHudLayout();

    // Dialogue box - bottom of screen
    dialogueBox = DialogueBox();
    dialogueBox.size = Vector2(size.x - 40, 130);
    dialogueBox.position = Vector2(size.x / 2, size.y - 20);
    camera.viewport.add(dialogueBox);

    // Save indicator - top right of screen
    _saveIndicator = TextComponent(
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
      ),
      text: '',
      anchor: Anchor.topRight,
      position: Vector2(size.x - 16, 16),
    );
    _saveIndicator.priority = 100;
    camera.viewport.add(_saveIndicator);

    _startAutoSave();

    // Camera setup
    camera.viewfinder.anchor = Anchor.center;
    camera.follow(player, maxSpeed: double.infinity);

    // Initialize transition zones
    map1ToMap2Zone = PolygonComponent([
      Vector2(225, 300),
      Vector2(260, 300),
      Vector2(240, 320),
      Vector2(253, 320),
    ]);

    // House door zone (map1) - door opening at tiles 14-16, rows 19-20
    houseDoorZone = PolygonComponent([
      Vector2(224, 304),
      Vector2(272, 304),
      Vector2(272, 336),
      Vector2(224, 336),
    ]);

    // House exit zone (house interior) - door at cols 7-9, row 12
    houseExitZone = PolygonComponent([
      Vector2(112, 192),
      Vector2(160, 192),
      Vector2(160, 208),
      Vector2(112, 208),
    ]);
  }

  Future<void> _scatterTrash() async {
    final files = [
      'apple peel.png',
      'bananaPeel.png',
      'cardboard box.png',
      'Origami Crane.png',
      'Plastic Bag.png',
      'Plastic Bottle.png',
      'Tin.png',
    ];

    final rnd = math.Random();
    final tileWidth = background.map.tileMap.map.tileWidth?.toDouble() ?? 64.0;
    final tileHeight = background.map.tileMap.map.tileHeight?.toDouble() ?? 64.0;
    final mapWidth = (background.map.tileMap.map.width ?? 10) * tileWidth;
    final mapHeight = (background.map.tileMap.map.height ?? 10) * tileHeight;

    for (final file in files) {
      try {
        final data = await rootBundle.load('assets/trash/$file');
        final bytes = data.buffer.asUint8List();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final img = frame.image;

        // Choose size per asset (smaller crane, larger box)
        final lower = file.toLowerCase();
        final itemSize = (lower.contains('origami') || lower.contains('crane'))
            ? Vector2(32, 32)
            : (lower.contains('cardboard') || lower.contains('box'))
                ? Vector2(64, 64)
                : Vector2(48, 48);

        // Try a few times to find a non-colliding position using the item size
        Vector2? chosen;
        for (var i = 0; i < 12; i++) {
          final candidate = Vector2(rnd.nextDouble() * mapWidth, rnd.nextDouble() * mapHeight);
          if (!_wouldCollideWithMap(candidate, itemSize)) {
            chosen = candidate;
            break;
          }
        }

        chosen ??= _playerFeetDropPosition(itemSize);

        final comp = BananaPeel(
          sprite: Sprite(img),
          size: itemSize,
          position: chosen,
        );
        world.add(comp);

        final target = _InteractionTarget(
          position: () => comp.position,
          range: 50,
          label: 'pick up',
          onInteract: () {
            _pickupItem(comp);
          },
        );
        _interactionTargets.add(target);
        _itemTargets[comp] = target;
      } catch (e) {
        // ignore missing assets or decode errors
      }
    }
  }

  Future<void> _placeBinNearPlayer() async {
    final tileDistance = 5 * 64.0;
    final binSize = Vector2(48, 64);
    final playerStart = Vector2(271, 640);

    final candidates = [
      playerStart + Vector2(tileDistance, 0),
      playerStart + Vector2(-tileDistance, 0),
      playerStart + Vector2(0, tileDistance),
      playerStart + Vector2(0, -tileDistance),
    ];

    Vector2? chosen;
    for (final pos in candidates) {
      if (!_wouldCollideWithMap(pos, binSize)) {
        chosen = pos;
        break;
      }
    }

    chosen ??= candidates.first;

    final bin = Bin(position: chosen);
    await world.add(bin);

    final binTarget = _InteractionTarget(
      position: () => bin.position,
      range: 60,
      label: 'sort',
      onInteract: () {
        // TODO: implement trash sorting logic
      },
    );
    _interactionTargets.add(binTarget);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    _updateHudLayout();
  }

  void _updateHudLayout() {
    if (!_hudReady) {
      return;
    }

    const edgeMargin = 24.0;
    const buttonGap = 16.0;

    final bottomRightX = size.x - edgeMargin - (inventoryButton.size.x / 2);
    final bottomRightY = size.y - edgeMargin - (inventoryButton.size.y / 2);

    inventoryButton.position = Vector2(bottomRightX, bottomRightY);
    interactButton.position = Vector2(
      bottomRightX,
      bottomRightY - inventoryButton.size.y - buttonGap,
    );
  }

  Future<void> changeMap(String newMap, {Vector2? newPosition}) async {
    background.removeFromParent();

    if (currentMap == 'map1') {
      george.removeFromParent();
    }

    currentMap = newMap;
    background = BackgroundComponent(mapName: newMap);
    background.priority = -1;
    await world.add(background);

    if (currentMap == 'map1') {
      george = GeorgeNPC(_georgeImage);
      george.position = Vector2(476, 760);
      await world.add(george);
    }

    if (newPosition != null) {
      player.position = newPosition;
    }
  }

  @override
  void update(double dt) {
    player.updateMovement(joystick, dt, size);

    george.priority = george.position.y.toInt();
    player.priority = player.position.y.toInt();

    if (showDebugCoordinates) {
      print('Player: ${player.position}');
    }

    // Update interact button text based on available interactions
    _updateInteractButtonText();

    // // Check for map transitions
    // if (currentMap == 'map1' && map1ToMap2Zone.containsPoint(player.position)) {
    //   changeMap('map2', newPosition: Vector2(100, 100));
    // }

    // if (currentMap == 'map1' && houseDoorZone.containsPoint(player.position)) {
    //   changeMap('house', newPosition: Vector2(136, 178));
    // }

    // if (currentMap == 'house' && houseExitZone.containsPoint(player.position)) {
    //   changeMap('map1', newPosition: Vector2(248, 340));
    // }

    super.update(dt);
  }

  void _startAutoSave() {
    _autoSaveTimer = async.Timer.periodic(const Duration(seconds: 20), (_) async {
      await _performSave();
    });
  }

  Future<void> _performSave() async {
    if (_isSaving) return;
    _isSaving = true;

    _saveIndicator.text = 'Saving...';

    final data = GameData(
      playerX: player.position.x,
      playerY: player.position.y,
      currentMap: currentMap,
      inventory: List.from(inventory),
    );

    await SaveManager.save(data);

    _saveIndicator.text = 'Saved!';
    await Future.delayed(const Duration(seconds: 2));
    _saveIndicator.text = '';
    _isSaving = false;
  }

  Future<void> _loadGameData() async {
    final data = await SaveManager.load();
    if (data == null) return;

    inventory = List.from(data.inventory);

    if (data.currentMap != currentMap) {
      changeMap(data.currentMap, newPosition: Vector2(data.playerX, data.playerY));
    } else {
      player.position = Vector2(data.playerX, data.playerY);
    }
  }

  @override
  void onRemove() {
    _autoSaveTimer?.cancel();
    super.onRemove();
  }

  void _updateInteractButtonText() {
    _InteractionTarget? closestTalk;
    _InteractionTarget? closestOther;
    var closestTalkDist = double.infinity;
    var closestOtherDist = double.infinity;

    for (final candidate in _interactionTargets) {
      final distance = (player.position - candidate.position()).length;
      if (distance <= candidate.range) {
        if (candidate.label.toLowerCase() == 'talk') {
          if (distance < closestTalkDist) {
            closestTalkDist = distance;
            closestTalk = candidate;
          }
        } else {
          if (distance < closestOtherDist) {
            closestOtherDist = distance;
            closestOther = candidate;
          }
        }
      }
    }

    if (closestTalk != null) {
      interactButton.actionText = closestTalk.label;
    } else if (heldItem != null) {
      interactButton.actionText = 'drop';
    } else if (closestOther != null) {
      interactButton.actionText = closestOther.label;
    } else {
      interactButton.actionText = '...';
    }
  }

  void _handleInteract() {
    if (dialogueBox.isVisible) {
      dialogueBox.dismiss();
      return;
    }
    _InteractionTarget? closestTalk;
    _InteractionTarget? closestOther;
    var closestTalkDist = double.infinity;
    var closestOtherDist = double.infinity;

    for (final candidate in _interactionTargets) {
      final distance = (player.position - candidate.position()).length;
      if (distance <= candidate.range) {
        if (candidate.label.toLowerCase() == 'talk') {
          if (distance < closestTalkDist) {
            closestTalkDist = distance;
            closestTalk = candidate;
          }
        } else {
          if (distance < closestOtherDist) {
            closestOtherDist = distance;
            closestOther = candidate;
          }
        }
      }
    }

    // Priority: talk > drop (if holding) > other interactions (e.g., pick up)
    if (closestTalk != null) {
      _facePlayerTowards(closestTalk.position());
      closestTalk.onInteract();
      return;
    }

    if (heldItem != null) {
      _dropHeldItem();
      return;
    }

    if (closestOther != null) {
      _facePlayerTowards(closestOther.position());
      closestOther.onInteract();
      return;
    }
  }

  void _pickupItem(PositionComponent item) {
    if (heldItem != null) return;

    // Remove world target for this item
    final target = _itemTargets.remove(item);
    if (target != null) {
      _interactionTargets.remove(target);
    }

    // Remove the item from the world
    item.removeFromParent();

    // Attach a sprite copy to the player (above head)
    final sprite = (item is SpriteComponent) ? item.sprite : null;
    // Place the held item over the player's hair: slightly right and a bit lower
    heldItem = SpriteComponent(
      sprite: sprite,
      size: item.size,
      anchor: Anchor.center,
    );
    player.add(heldItem!);
    // Local position relative to player's center: x to the right, y negative to sit above head
    // Adjust placement: move 5 pixels left and 15 pixels lower from previous values
    heldItem!.position = Vector2(
      // Nudge: 5px further left and additional 7px lower
      player.size.x * 0.72 - 25,
      -player.size.y * 0.45 + 67,
    );
    // Ensure it renders above the player
    heldItem!.priority = player.priority + 1;
  }

  void _dropHeldItem() {
    if (heldItem == null) return;

    final dropPos = _findDropPosition();

    final dropped = BananaPeel(
      sprite: heldItem!.sprite,
      size: heldItem!.size,
      position: dropPos,
    );
    world.add(dropped);

    final droppedTarget = _InteractionTarget(
      position: () => dropped.position,
      range: 50,
      label: 'pick up',
      onInteract: () {
        _pickupItem(dropped);
      },
    );
    _interactionTargets.add(droppedTarget);
    _itemTargets[dropped] = droppedTarget;

    heldItem!.removeFromParent();
    heldItem = null;
  }

  Vector2 _findDropPosition() {
    final itemSize = heldItem?.size.clone() ?? Vector2.all(48);
    final frontDrop = player.position + _directionVector(player.direction) * 64.0;

    if (!_wouldCollideWithMap(frontDrop, itemSize)) {
      return frontDrop;
    }

    return _playerFeetDropPosition(itemSize);
  }

  Vector2 _playerFeetDropPosition(Vector2 itemSize) =>
      player.position + Vector2(0, player.size.y / 2 - itemSize.y / 2);

  Vector2 _directionVector(int direction) {
    switch (direction) {
      case 1:
        return Vector2(-1, 0);
      case 2:
        return Vector2(1, 0);
      case 4:
        return Vector2(0, -1);
      case 3:
      default:
        return Vector2(0, 1);
    }
  }

  bool _wouldCollideWithMap(Vector2 centerPosition, Vector2 itemSize) {
    final halfSize = itemSize / 2;
    final left = centerPosition.x - halfSize.x;
    final top = centerPosition.y - halfSize.y;
    final right = left + itemSize.x;
    final bottom = top + itemSize.y;

    for (final hitbox in background.getCollisions()) {
      final hitLeft = hitbox.position.x;
      final hitTop = hitbox.position.y;
      final hitRight = hitLeft + hitbox.size.x;
      final hitBottom = hitTop + hitbox.size.y;

      final overlaps = left < hitRight && right > hitLeft && top < hitBottom && bottom > hitTop;
      if (overlaps) {
        return true;
      }
    }

    if (george.isMounted && _wouldCollideWithGeorge(centerPosition, itemSize)) {
      return true;
    }

    return false;
  }

  bool _wouldCollideWithGeorge(Vector2 centerPosition, Vector2 itemSize) {
    final georgeLeft = george.position.x - george.size.x / 2 + george.size.x * 0.2;
    final georgeTop = george.position.y - george.size.y / 2 + george.size.y * 0.3 - 1;
    final georgeRight = georgeLeft + george.size.x * 0.6;
    final georgeBottom = georgeTop + george.size.y * 0.6 + 2;

    final halfSize = itemSize / 2;
    final left = centerPosition.x - halfSize.x;
    final top = centerPosition.y - halfSize.y;
    final right = left + itemSize.x;
    final bottom = top + itemSize.y;

    return left < georgeRight && right > georgeLeft && top < georgeBottom && bottom > georgeTop;
  }

  void _facePlayerTowards(Vector2 targetPosition) {
    final diff = targetPosition - player.position;
    final angle = math.atan2(diff.y, diff.x);
    final degrees = (angle * 180 / math.pi + 360) % 360;

    if (degrees >= 315 || degrees < 45) {
      player.animation = player.rightAnimation;
      player.direction = 2;
    } else if (degrees >= 45 && degrees < 135) {
      player.animation = player.downAnimation;
      player.direction = 3;
    } else if (degrees >= 135 && degrees < 225) {
      player.animation = player.leftAnimation;
      player.direction = 1;
    } else {
      player.animation = player.upAnimation;
      player.direction = 4;
    }
  }
}

class _InteractionTarget {
  _InteractionTarget({
    required this.position,
    required this.range,
    required this.label,
    required this.onInteract,
  });

  final Vector2 Function() position;
  final double range;
  final String label;
  final void Function() onInteract;
}
