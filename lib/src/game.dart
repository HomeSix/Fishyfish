import 'dart:math' as math;
import 'dart:ui' show Image;
import 'package:flame/game.dart';
import 'package:flame/components.dart';

import 'player/player.dart';
import 'onScreen/joystick.dart';
import 'background/background_component.dart';
import 'npc/george.dart';
import 'onScreen/interact_button.dart';
import 'ui/dialogue_box.dart';
import 'onScreen/inventory_button.dart';

class FishyFishGame extends FlameGame with HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late BackgroundComponent background;
  late GeorgeNPC george;
  late InteractButton interactButton;
  late InventoryButton inventoryButton;
  late DialogueBox dialogueBox;
  late Image _georgeImage;
  String currentMap = 'map1';
  bool showDebugCoordinates = false; // Set to true when placing zones
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
        onInteract: () {
          dialogueBox.show('George', 'Do you know? Hafiz is gay');
        },
      ),
    );

    // Joystick - add to camera viewport (stays on screen)
    joystick = createJoystick();
    camera.viewport.add(joystick);

    // Interact button - right side of screen
    interactButton = InteractButton(
      onTap: _handleInteract,
    );
    interactButton.position = Vector2(size.x - 90, size.y - 135);
    camera.viewport.add(interactButton);

    inventoryButton = InventoryButton(
      onTap: () {
        overlays.add('InventoryOverlay');
      },
    );
    inventoryButton.position = Vector2(size.x - 230, size.y - 135);
    camera.viewport.add(inventoryButton);

    // Dialogue box - bottom of screen
    dialogueBox = DialogueBox();
    dialogueBox.size = Vector2(size.x - 40, 130);
    dialogueBox.position = Vector2(size.x / 2, size.y - 20);
    camera.viewport.add(dialogueBox);

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
      george.position = Vector2(448, 270);
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

    // Check for map transitions
    if (currentMap == 'map1' && map1ToMap2Zone.containsPoint(player.position)) {
      changeMap('map2', newPosition: Vector2(100, 100));
    }

    if (currentMap == 'map1' && houseDoorZone.containsPoint(player.position)) {
      changeMap('house', newPosition: Vector2(136, 178));
    }

    if (currentMap == 'house' && houseExitZone.containsPoint(player.position)) {
      changeMap('map1', newPosition: Vector2(248, 340));
    }

    super.update(dt);
  }

  void _handleInteract() {
    if (dialogueBox.isVisible) {
      dialogueBox.dismiss();
      return;
    }

    _InteractionTarget? target;
    var closestDistance = double.infinity;

    for (final candidate in _interactionTargets) {
      final distance = (player.position - candidate.position()).length;
      if (distance <= candidate.range && distance < closestDistance) {
        closestDistance = distance;
        target = candidate;
      }
    }

    if (target == null) {
      return;
    }

    _facePlayerTowards(target.position());
    target.onInteract();
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
    required this.onInteract,
  });

  final Vector2 Function() position;
  final double range;
  final void Function() onInteract;
}
