import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameData {
  final String currentMap;
  final List<String> inventory;

  GameData({
    required this.currentMap,
    required this.inventory,
  });

  Map<String, dynamic> toJson() => {
    'currentMap': currentMap,
    'inventory': inventory,
  };

  factory GameData.fromJson(Map<String, dynamic> json) => GameData(
    currentMap: json['currentMap'] as String,
    inventory: List<String>.from(json['inventory'] as List),
  );
}

class SaveManager {
  static const String _saveKey = 'fishyfish_save_data';
  static const String _highScoreKey = 'fishyfish_high_score';

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

  static Future<int> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }

  static Future<void> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_highScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_highScoreKey, score);
    }
  }
}
