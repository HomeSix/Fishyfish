import 'dart:async' as async;
import 'dart:math' as math;
import 'dart:ui' show Image, FontWeight, Color, Offset, Shadow, Rect, TextStyle;
import 'package:flame/game.dart';
import 'package:flame/components.dart';

import 'package:flame/text.dart';

import 'player/player.dart';
import 'onScreen/joystick.dart';
import 'background/background_component.dart';
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
  late InteractButton interactButton;
  late InventoryButton inventoryButton;
  late DialogueBox dialogueBox;
  late Image _bananaImage;
  BananaPeel? banana;
  SpriteComponent? heldItem;
  final Map<PositionComponent, _InteractionTarget> _itemTargets = {};
  final Map<PositionComponent, String> _trashFilenames = {};
  String? _heldTrashFile;
  String currentMap = 'hub';
  bool showDebugCoordinates = false;
  bool _hudReady = false;
  bool _isChangingMap = false;
  async.Timer? _autoSaveTimer;
  late TextComponent _saveIndicator, _scoreText, _timerText, _highScoreText;
  bool _isSaving = false;
  final List<_InteractionTarget> _interactionTargets = [];

  int score = 0;
  int highScore = 0;
  double _timeRemaining = 120;
  String _minigameState = 'idle'; // idle | pending | active | finished
  List<String>? _activeDialoguePages;
  int _activeDialogueIndex = 0;

  static const _npcName = 'Ranger Jack';
  static const _npcDialoguePages = [
    "Hei! Pantai ni bersepah!\n"
        "Botol, plastik, kotak… tolong\n"
        "aku bersihkan semua ni!",
    "Ada 3 tong sampah:\n"
        "Perang untuk sisa makanan,\n"
        "Biru untuk kertas, Kuning untuk plastik.",
    "Pergi dekat sampah dan tekan\n"
        "butang interaksi untuk ambil.",
    "Lepas tu pergi dekat tong yang\n"
        "betul dan tekan butang interaksi\n"
        "lagi. Betul +1, salah -1.",
    "Kau ada 120 saat. Berani\n"
        "ke tak? Jom bersihkan pantai!",
  ];
  int _npcDialogueIndex = 0;

  static const _welcomeBoardName = 'Papan Utama';
  static const _welcomeBoardDialoguePages = [
    'Selamat datang ke Fishyfish!',
    'Dahulu, lautan dikenali sebagai “Laut Biru Abadi” — tempat yang penuh dengan kehidupan, warna, dan keseimbangan antara manusia dan alam. Ikan-ikan berenang bebas, terumbu karang berkembang, dan hidupan laut hidup harmoni.',
    'Namun, lama-kelamaan, manusia mula mencemarkan laut dengan pelbagai bahan buangan — plastik, sisa toksik, dan sampah sarap. Laut yang dulunya jernih kini semakin keruh. Banyak hidupan laut jatuh sakit, habitat musnah, dan ada yang hampir pupus.',
    'Pemain mengambil peranan sebagai seorang penyelam muda yang berani, dihantar untuk meneroka dan memulihkan lautan. Setiap kali menyelam, pemain akan menemui pelbagai “sea stuff” yang yang masih hidup dan perlukan bantuan, ada juga yang telah rosak akibat pencemaran.',
    'Sepanjang perjalanan, pemain akan:\n\n- Membersihkan ikan dan membantu hidupan laut yang terjejas\n- Mengutip dan mengurus bahan buangan dengan betul\n- Belajar tentang jenis sampah dan kesannya terhadap alam\n- Meneroka kawasan laut berbeza yang semakin terjejas',
    'Namun, semakin dalam pemain menyelam, semakin jelas bahawa kerosakan ini bukan sesuatu yang kecil. Laut sedang “sakit”, dan hanya dengan usaha berterusan, keseimbangan itu boleh dikembalikan.\n\nMatlamat utama pemain bukan sekadar untuk bermain, tetapi untuk memulihkan Laut Biru Abadi dan mengembalikan harapan kepada semua hidupan laut.',
  ];

  static const _routeBoardDialogues = {
    'to_beach_board': 'Laluan ini menuju ke Pantai.\n\nTeruskan perjalanan untuk ke kawasan pantai.',
    'to_museum_board': 'Laluan ini menuju ke Muzium.\n\nTeruskan perjalanan untuk ke kawasan muzium.',
  };

  static const _animalDescriptions = {
    'dugong': 'Dugong adalah mamalia laut yang\n'
        'lembut dan memakan rumput laut.\n'
        'Ia juga dikenali sebagai "lembu laut"!\n'
        'Status: Terancam',
    'mammoth': 'Mammoth ialah gajah purba yang\n'
        'hidup zaman air batu.\n'
        'Status: Sudah pupus',
    'dino': 'Dinosaur adalah reptilia gergasi\n'
        'yang hidup jutaan tahun dahulu.\n'
        'Mereka pupus akibat meteor!\n'
        'Status: Sudah pupus',
    'tasmanian': 'Harimau Tasmania (Thylacine) ialah\n'
        'marsupial karnivor.\n'
        'Status: Sudah pupus',
    'tapir': 'Tapir adalah haiwan yang pemalu\n'
        'dan suka tinggal di hutan tebal.\n'
        'Status: Terancam',
    'rhino': 'Badak sumbu adalah haiwan besar\n'
        'dengan satu atau dua tanduk.\n'
        'Status: Terancam',
    'orang utan': 'Orang utan adalah monyet merah\n'
        'yang bijak dan tinggal di pokok.\n'
        'Status: Terancam',
    'dodo bird': 'Burung Dodo tidak boleh terbang.\n'
        'Ia pupus sejak tahun 1600-an.\n'
        'Status: Sudah pupus',
    'elephant': 'Gajah adalah haiwan darat\n'
        'terbesar di dunia. Ia sangat\n'
        'pintar dan kuat.\n'
        'Status: Terancam',
    'harimau malaya': 'Harimau Malaya adalah simbol\n'
        'kebanggaan Malaysia. Kini hanya\n'
        'tinggal kurang dari 150 ekor!\n'
        'Status: Terancam',
  };

  List<String> inventory = ["test item", "mavinesh"];
  void addItemToInventory(String item) {
    inventory.add(item);
  }

  static const _binForTrash = {
    'apple peel.png': 'brown',
    'bananaPeel.png': 'brown',
    'cardboard box.png': 'blue',
    'Origami Crane.png': 'blue',
    'Plastic Bag.png': 'yellow',
    'Plastic Bottle.png': 'yellow',
    'Tin.png': 'yellow',
  };

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

    _setPlayerToSpawn();

    _setupBins();

    highScore = await SaveManager.loadHighScore();

    // Banana peel item - only on beach map
    if (currentMap == 'beach') {
      final data = await rootBundle.load('assets/trash/bananaPeel.png');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _bananaImage = frame.image;
      banana = BananaPeel(
        sprite: Sprite(_bananaImage),
        size: Vector2(29, 29),
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
    }

    // Scatter remaining trash assets across the map
    await _scatterTrash();

    // Place a bin 5 tiles (320px) right of the player start position
    // await _placeBinNearPlayer();

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
    dialogueBox = DialogueBox(onDismissCallback: () {
      if (_activeDialoguePages != null) {
        _clearActiveDialogue();
        overlays.add('WelcomePopup');
      }
    });
    dialogueBox.size = Vector2(size.x - 40, 180);
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

    // Score text - top left
    _scoreText = TextComponent(
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF), fontSize: 22, fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(2, 2))],
        ),
      ),
      text: '',
      anchor: Anchor.topLeft,
      position: Vector2(16, 16),
    );
    _scoreText.priority = 100;
    camera.viewport.add(_scoreText);

    // Timer text - top center
    _timerText = TextComponent(
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF), fontSize: 22, fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(2, 2))],
        ),
      ),
      text: '',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 16),
    );
    _timerText.priority = 100;
    camera.viewport.add(_timerText);

    // High score text - top right, below save indicator
    _highScoreText = TextComponent(
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(2, 2))],
        ),
      ),
      text: 'High Score: $highScore',
      anchor: Anchor.topRight,
      position: Vector2(size.x - 16, 48),
    );
    _highScoreText.priority = 100;
    camera.viewport.add(_highScoreText);

    _startAutoSave();

    // Camera setup
    camera.viewfinder.anchor = Anchor.center;
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
    final poly = background.trashSpawnPoly;
    if (poly == null || poly.length < 3) return;

    for (final file in files) {
      for (var n = 0; n < 3; n++) {
        try {
        final data = await rootBundle.load('assets/trash/$file');
        final bytes = data.buffer.asUint8List();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final img = frame.image;

        final lower = file.toLowerCase();
        final itemSize = (lower.contains('origami') || lower.contains('crane'))
            ? Vector2(19, 19)
            : (lower.contains('cardboard') || lower.contains('box'))
                ? Vector2(39, 39)
                : Vector2(29, 29);

        Vector2? chosen;
        for (var i = 0; i < 30; i++) {
          final candidate = _randomPointInPolygon(poly, rnd);
          if (!_wouldCollideWithMap(candidate, itemSize)) {
            chosen = candidate;
            break;
          }
        }
        chosen ??= _randomPointInPolygon(poly, rnd);

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
        _trashFilenames[comp] = file;
      } catch (e) {
        // ignore missing assets or decode errors
      }
      }
    }
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

  Future<void> changeMap(String newMap, [String? spawnType]) async {
    _isChangingMap = true;
    _heldTrashFile = null;
    if (heldItem != null) {
      heldItem!.removeFromParent();
      heldItem = null;
    }
    banana?.removeFromParent();
    banana = null;
    for (final comp in _itemTargets.keys) {
      comp.removeFromParent();
    }
    _interactionTargets.clear();
    _itemTargets.clear();
    _trashFilenames.clear();
    background.removeFromParent();

    _minigameState = 'idle';
    score = 0;
    _timeRemaining = 120;
    _scoreText.text = '';
    _timerText.text = '';

    currentMap = newMap;
    background = BackgroundComponent(mapName: newMap);
    background.priority = -1;
    await world.add(background);

    _setPlayerToSpawn(spawnType);
    _setupBins();
    if (newMap == 'beach') {
      await _scatterTrash();
    }

    _isChangingMap = false;
  }

  @override
  void update(double dt) {
    final previousPlayerPosition = player.position.clone();
    player.updateMovement(joystick, dt, size);

    if (_playerCollides(player.position)) {
      player.position = previousPlayerPosition;
    }

    player.priority = player.position.y.toInt();

    if (showDebugCoordinates) {
      print('Player: ${player.position}');
    }

    // --- Minigame zone detection ---
    _checkMinigameZone();

    // --- Map transitions ---
    if (!_isChangingMap) _checkMapTransitions();

    // --- Minigame timer countdown ---
    if (_minigameState == 'active') {
      _timeRemaining -= dt;
      _timerText.text = _timeRemaining.ceil().toString();
      if (_timeRemaining <= 0) {
        _timeRemaining = 0;
        _endGame();
      }
    }

    _updateInteractButtonText();

    super.update(dt);

    if (_isChangingMap) return;

    final map = background.map.tileMap.map;
    final double mapW = (map.width * map.tileWidth).toDouble();
    final double mapH = (map.height * map.tileHeight).toDouble();
    final half = player.size / 2;
    player.position.x = player.position.x.clamp(half.x, mapW - half.x);
    player.position.y = player.position.y.clamp(half.y, mapH - half.y);

    final halfViewport = size / 2;
    final clampX = mapW <= halfViewport.x * 2
        ? mapW / 2
        : player.position.x.clamp(halfViewport.x, mapW - halfViewport.x).toDouble();
    final clampY = mapH <= halfViewport.y * 2
        ? mapH / 2
        : player.position.y.clamp(halfViewport.y, mapH - halfViewport.y).toDouble();
    camera.viewfinder.position = Vector2(clampX, clampY);
  }

  void _checkMinigameZone() {
    // After game over dialogue dismissed, reset to idle
    if (_minigameState == 'finished' && !dialogueBox.isVisible) {
      _minigameState = 'idle';
      return;
    }

    // If waiting for dialogue dismissal, advance pages or start minigame
    if (_minigameState == 'pending' && !dialogueBox.isVisible) {
      _npcDialogueIndex++;
      if (_npcDialogueIndex < _npcDialoguePages.length) {
        dialogueBox.show(_npcName, _npcDialoguePages[_npcDialogueIndex]);
      } else {
        _startMinigame();
      }
      return;
    }

    if (_minigameState == 'active' || dialogueBox.isVisible) return;

    final zone = background.minigameStartZone;
    if (zone == null) return;

    final feetSize = Vector2(30, 20);
    final dy = (player.size.y / 2 - feetSize.y / 2) - 16;
    final feetRect = Rect.fromCenter(
      center: Offset(player.position.x, player.position.y + dy),
      width: feetSize.x,
      height: feetSize.y,
    );

    if (feetRect.overlaps(zone)) {
      _minigameState = 'pending';
      _npcDialogueIndex = 0;
      dialogueBox.show(_npcName, _npcDialoguePages[0]);
    }
  }

  void _checkMapTransitions() {
    if (dialogueBox.isVisible) return;

    final feetSize = Vector2(30, 20);
    final dy = (player.size.y / 2 - feetSize.y / 2) - 16;
    final feetRect = Rect.fromCenter(
      center: Offset(player.position.x, player.position.y + dy),
      width: feetSize.x,
      height: feetSize.y,
    );

    final toBeach = background.toBeachZone;
    if (toBeach != null && feetRect.overlaps(toBeach) && currentMap == 'hub') {
      changeMap('beach');
      return;
    }

    final toMuseum = background.toMuseumZone;
    if (toMuseum != null && feetRect.overlaps(toMuseum) && currentMap == 'hub') {
      changeMap('museum');
      return;
    }

    final toHub = background.toHubZone;
    if (toHub != null && feetRect.overlaps(toHub)) {
      if (currentMap == 'beach') changeMap('hub', 'from_beach');
      if (currentMap == 'museum') changeMap('hub', 'from_museum');
    }
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
      changeMap(data.currentMap);
    }
  }

  @override
  void onRemove() {
    _autoSaveTimer?.cancel();
    super.onRemove();
  }

  void _updateInteractButtonText() {
    _InteractionTarget? closestTalk;
    _InteractionTarget? closestRead;
    _InteractionTarget? closestBin;
    _InteractionTarget? closestOther;
    var closestTalkDist = double.infinity;
    var closestReadDist = double.infinity;
    var closestBinDist = double.infinity;
    var closestOtherDist = double.infinity;

    for (final candidate in _interactionTargets) {
      final distance = (player.position - candidate.position()).length;
      if (distance <= candidate.range) {
        final label = candidate.label.toLowerCase();
        if (label == 'talk') {
          if (distance < closestTalkDist) {
            closestTalkDist = distance;
            closestTalk = candidate;
          }
        } else if (label == 'read') {
          if (distance < closestReadDist) {
            closestReadDist = distance;
            closestRead = candidate;
          }
        } else if (candidate.label.contains('bin')) {
          if (distance < closestBinDist) {
            closestBinDist = distance;
            closestBin = candidate;
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
    } else if (closestRead != null) {
      interactButton.actionText = closestRead.label;
    } else if (heldItem != null && closestBin != null) {
      interactButton.actionText = 'sort';
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
      if (_activeDialoguePages != null && _activeDialogueIndex < _activeDialoguePages!.length - 1) {
        _activeDialogueIndex++;
        dialogueBox.show(_welcomeBoardName, _activeDialoguePages![_activeDialogueIndex]);
        return;
      }
      final wasActive = _activeDialoguePages != null;
      _clearActiveDialogue();
      dialogueBox.dismiss();
      if (wasActive) {
        overlays.add('WelcomePopup');
      }
      return;
    }
    _InteractionTarget? closestTalk;
    _InteractionTarget? closestRead;
    _InteractionTarget? closestBin;
    _InteractionTarget? closestOther;
    var closestTalkDist = double.infinity;
    var closestReadDist = double.infinity;
    var closestBinDist = double.infinity;
    var closestOtherDist = double.infinity;

    for (final candidate in _interactionTargets) {
      final distance = (player.position - candidate.position()).length;
      if (distance <= candidate.range) {
        final label = candidate.label.toLowerCase();
        if (label == 'talk') {
          if (distance < closestTalkDist) {
            closestTalkDist = distance;
            closestTalk = candidate;
          }
        } else if (label == 'read') {
          if (distance < closestReadDist) {
            closestReadDist = distance;
            closestRead = candidate;
          }
        } else if (candidate.label.contains('bin')) {
          if (distance < closestBinDist) {
            closestBinDist = distance;
            closestBin = candidate;
          }
        } else {
          if (distance < closestOtherDist) {
            closestOtherDist = distance;
            closestOther = candidate;
          }
        }
      }
    }

    // Priority: talk/read > sort (if near bin + holding) > drop (if holding) > other interactions (e.g., pick up)
    if (closestTalk != null) {
      _facePlayerTowards(closestTalk.position());
      closestTalk.onInteract();
      return;
    }

    if (closestRead != null) {
      _facePlayerTowards(closestRead.position());
      closestRead.onInteract();
      return;
    }

    if (heldItem != null && closestBin != null) {
      _facePlayerTowards(closestBin.position());
      _sortTrashIntoBin(closestBin.label);
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

    if (_minigameState != 'active') _startMinigame();

    // Remove world target for this item
    final target = _itemTargets.remove(item);
    if (target != null) {
      _interactionTargets.remove(target);
    }

    // Track filename for bin sorting
    _heldTrashFile = _trashFilenames.remove(item);

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
      player.size.x * 0.72 - 15,
      -player.size.y * 0.45 + 40,
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
    final temp = _heldTrashFile;
    if (temp != null) _trashFilenames[dropped] = temp;

    heldItem!.removeFromParent();
    heldItem = null;
    _heldTrashFile = null;
  }

  Vector2 _findDropPosition() {
    final itemSize = heldItem?.size.clone() ?? Vector2.all(48);
    final frontDrop = player.position + _directionVector(player.direction) * 32.0;

    if (!_wouldCollideWithMap(frontDrop, itemSize)) {
      final map = background.map.tileMap.map;
      final mapW = map.width * map.tileWidth;
      final mapH = map.height * map.tileHeight;
      final half = itemSize / 2;
      if (frontDrop.x - half.x >= 0 && frontDrop.x + half.x <= mapW &&
          frontDrop.y - half.y >= 0 && frontDrop.y + half.y <= mapH) {
        return frontDrop;
      }
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

  /// Check if a rectangle (centered at [centerPos] with [size]) overlaps any collision shape
  bool _wouldCollideWithMap(Vector2 centerPos, Vector2 size) {
    final half = size / 2;
    final rect = Rect.fromLTWH(
      centerPos.x - half.x, centerPos.y - half.y, size.x, size.y,
    );

    for (final r in background.collisionRects) {
      if (rect.overlaps(r)) return true;
    }
    for (final poly in background.collisionPolys) {
      if (_rectOverlapsPolygon(rect, poly)) return true;
    }
    return false;
  }

  bool _playerCollides(Vector2 centerPos) {
    final feetSize = Vector2(30, 20);
    final dy = (player.size.y / 2 - feetSize.y / 2) - 16;
    final feetCenter = Vector2(centerPos.x, centerPos.y + dy);
    return _wouldCollideWithMap(feetCenter, feetSize);
  }

  void _setupBins() {
    for (final binData in background.bins) {
      final bin = Bin(position: Vector2(binData.x, binData.y));
      world.add(bin);

      final binName = binData.name;
      final range = math.max(binData.width, binData.height) * 1.2;
      _interactionTargets.add(_InteractionTarget(
        position: () => bin.position,
        range: range,
        label: binName,
        onInteract: () => _sortTrashIntoBin(binName),
      ));
    }

    for (final boardData in background.welcomeBoards) {
      _interactionTargets.add(_InteractionTarget(
        position: () => Vector2(boardData.x, boardData.y),
        range: math.max(boardData.width, boardData.height) * 1.5,
        label: 'read',
        onInteract: _showWelcomeBoardDialogue,
      ));
    }

    for (final routeData in background.routeBoards) {
      _interactionTargets.add(_InteractionTarget(
        position: () => Vector2(routeData.x, routeData.y),
        range: math.max(routeData.width, routeData.height) * 1.5,
        label: 'read',
        onInteract: () => _showRouteBoardDialogue(routeData.name),
      ));
    }

    for (final infoData in background.infoBoards) {
      _interactionTargets.add(_InteractionTarget(
        position: () => Vector2(infoData.x, infoData.y),
        range: math.max(infoData.width, infoData.height) * 1.5,
        label: 'info',
        onInteract: () => _showInfoBoardDialogue(infoData.name),
      ));
    }
  }

  void _setPlayerToSpawn([String? spawnType]) {
    List<Vector2>? poly;
    if (spawnType == 'from_beach') {
      poly = background.fromBeachSpawnPoly;
    } else if (spawnType == 'from_hub') {
      poly = background.fromHubSpawnPoly;
    } else if (spawnType == 'from_museum') {
      poly = background.fromMuseumSpawnPoly;
    } else {
      poly = background.playerSpawnPoly;
    }

    if (poly != null && poly.isNotEmpty) {
      double sx = 0, sy = 0;
      for (final p in poly) { sx += p.x; sy += p.y; }
      player.position = Vector2(sx / poly.length, sy / poly.length);
    } else {
      final map = background.map.tileMap.map;
      player.position = Vector2(
        map.width * map.tileWidth / 2,
        map.height * map.tileHeight / 2,
      );
    }
  }

  /// True if [rect] overlaps with any edge of [poly] (points in world coords)
  bool _rectOverlapsPolygon(Rect rect, List<Vector2> poly) {
    final rectEdges = <List<Vector2>>[
      [Vector2(rect.left, rect.top), Vector2(rect.right, rect.top)],     // top
      [Vector2(rect.right, rect.top), Vector2(rect.right, rect.bottom)], // right
      [Vector2(rect.right, rect.bottom), Vector2(rect.left, rect.bottom)], // bottom
      [Vector2(rect.left, rect.bottom), Vector2(rect.left, rect.top)],   // left
    ];

    for (var i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      for (final edge in rectEdges) {
        if (_segmentsIntersect(edge[0], edge[1], a, b)) return true;
      }
    }
    return false;
  }

  bool _segmentsIntersect(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4) {
    final d1 = _cross(p3 - p1, p2 - p1);
    final d2 = _cross(p4 - p1, p2 - p1);
    final d3 = _cross(p1 - p3, p4 - p3);
    final d4 = _cross(p2 - p3, p4 - p3);

    if ((d1 > 0 && d2 < 0 || d1 < 0 && d2 > 0) &&
        (d3 > 0 && d4 < 0 || d3 < 0 && d4 > 0)) {
      return true;
    }

    if (d1 == 0 && _onSegment(p3, p1, p2)) return true;
    if (d2 == 0 && _onSegment(p4, p1, p2)) return true;
    if (d3 == 0 && _onSegment(p1, p3, p4)) return true;
    if (d4 == 0 && _onSegment(p2, p3, p4)) return true;

    return false;
  }

  double _cross(Vector2 a, Vector2 b) => a.x * b.y - a.y * b.x;

  bool _onSegment(Vector2 p, Vector2 q1, Vector2 q2) =>
      p.x <= math.max(q1.x, q2.x) && p.x >= math.min(q1.x, q2.x) &&
      p.y <= math.max(q1.y, q2.y) && p.y >= math.min(q1.y, q2.y);

  Vector2 _randomPointInPolygon(List<Vector2> poly, math.Random rnd) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in poly) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
    for (var i = 0; i < 50; i++) {
      final pt = Vector2(
        minX + rnd.nextDouble() * (maxX - minX),
        minY + rnd.nextDouble() * (maxY - minY),
      );
      if (_isPointInPolygon(pt, poly)) return pt;
    }
    return Vector2(minX + (maxX - minX) / 2, minY + (maxY - minY) / 2);
  }

  bool _isPointInPolygon(Vector2 point, List<Vector2> poly) {
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      if ((poly[i].y > point.y) != (poly[j].y > point.y) &&
          point.x < (poly[j].x - poly[i].x) * (point.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x) {
        inside = !inside;
      }
    }
    return inside;
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

  void _sortTrashIntoBin(String binName) {
    if (heldItem == null || _heldTrashFile == null) return;

    final expectedColour = _binForTrash[_heldTrashFile];
    final binColour = binName.split(' ').first;

    if (expectedColour == binColour) {
      score++;
      dialogueBox.show('System', 'Betul! +1');
    } else {
      score = math.max(0, score - 1);
      dialogueBox.show('System', 'Salah tong! -1');
    }
    _scoreText.text = 'Score: $score';

    heldItem!.removeFromParent();
    heldItem = null;
    _heldTrashFile = null;
    _spawnOneTrash();
  }

  Future<void> _spawnOneTrash() async {
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
    final poly = background.trashSpawnPoly;
    if (poly == null || poly.length < 3) return;

    final file = files[rnd.nextInt(files.length)];
    try {
      final data = await rootBundle.load('assets/trash/$file');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;

      final lower = file.toLowerCase();
      final itemSize = (lower.contains('origami') || lower.contains('crane'))
          ? Vector2(19, 19)
          : (lower.contains('cardboard') || lower.contains('box'))
              ? Vector2(39, 39)
              : Vector2(29, 29);

      Vector2? chosen;
      for (var i = 0; i < 30; i++) {
        final candidate = _randomPointInPolygon(poly, rnd);
        if (!_wouldCollideWithMap(candidate, itemSize)) {
          chosen = candidate;
          break;
        }
      }
      chosen ??= _randomPointInPolygon(poly, rnd);

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
      _trashFilenames[comp] = file;
    } catch (e) {
      // ignore missing assets or decode errors
    }
  }

  void _startMinigame() {
    _minigameState = 'active';
    score = 0;
    _timeRemaining = 120;
    _scoreText.text = 'Score: 0';
    _timerText.text = '120';
  }

  void _endGame() {
    _minigameState = 'finished';
    if (score > highScore) {
      highScore = score;
      SaveManager.saveHighScore(highScore);
      _highScoreText.text = 'High Score: $highScore';
    }
    _scoreText.text = '';
    _timerText.text = '';
    dialogueBox.show('Game Over', 'Your score: $score\nHigh score: $highScore');
  }

  void _showInfoBoardDialogue(String name) {
    final animalKey = name.split(' ').skip(1).join(' ');
    final desc = _animalDescriptions[animalKey];
    final displayName = animalKey[0].toUpperCase() + animalKey.substring(1);
    dialogueBox.show(displayName, desc ?? 'Tiada maklumat.');
  }

  void _showWelcomeBoardDialogue() {
    _activeDialoguePages = _welcomeBoardDialoguePages;
    _activeDialogueIndex = 0;
    dialogueBox.show(_welcomeBoardName, _activeDialoguePages!.first);
  }

  void _showRouteBoardDialogue(String boardKey) {
    final key = boardKey.toLowerCase();
    String title = 'Papan Tanda';
    String text = 'Laluan ini menuju ke destinasi seterusnya.';

    if (_routeBoardDialogues.containsKey(key)) {
      text = _routeBoardDialogues[key]!;
      if (key.contains('beach')) {
        title = 'Papan Pantai';
      } else if (key.contains('museum')) {
        title = 'Papan Muzium';
      }
    }

    dialogueBox.show(title, text);
  }

  void _clearActiveDialogue() {
    _activeDialoguePages = null;
    _activeDialogueIndex = 0;
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
