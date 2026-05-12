import 'package:flutter/material.dart';
import '../game.dart';

class InventoryButton extends StatelessWidget {
  final FishyFishGame game;
  const InventoryButton({super.key, required this.game});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: ElevatedButton(
        onPressed: () {
          game.overlays.add('InventoryOverlay');
          // Optionally remove the main button to avoid duplicates
          game.overlays.remove('InventoryButton');
        },
        child: const Text('Inventory'),
      ),
    );
  }
}