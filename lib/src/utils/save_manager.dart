import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameData {
  final double playerX;
  final double playerY;
  final String currentMap;
  final List<String> inventory;

  GameData({
    required this.playerX,
    required this.playerY,
    required this.currentMap,
    required this.inventory,
  });

  Map<String, dynamic> toJson() => {
    'playerX': playerX,
    'playerY': playerY,
    'currentMap': currentMap,
    'inventory': inventory,
  };

  factory GameData.fromJson(Map<String, dynamic> json) => GameData(
    playerX: (json['playerX'] as num).toDouble(),
    playerY: (json['playerY'] as num).toDouble(),
    currentMap: json['currentMap'] as String,
    inventory: List<String>.from(json['inventory'] as List),
  );
}

class SaveManager {
  static const String _saveKey = 'fishyfish_save_data';

  static Future<void> save(GameData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(data.toJson()));
  }

  static Future<GameData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_saveKey);
    if (json == null) return null;
    return GameData.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }
}
