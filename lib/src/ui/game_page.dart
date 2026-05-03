import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final FishyFishGame _game;

  @override
  void initState() {
    super.initState();
    _game = FishyFishGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(game: _game),
    );
  }
}
