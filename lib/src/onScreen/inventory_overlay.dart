import 'package:flutter/material.dart';
import '../game.dart';

class InventoryOverlay extends StatelessWidget {
  final FishyFishGame game;
  const InventoryOverlay({super.key, required this.game});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.all(24),
        child: SizedBox(
          width: 250,
          height: 350,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Inventory',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: game.inventory.length,
                  itemBuilder: (context, index) {
                    final item = game.inventory[index];
                    return ListTile(
                      title: Text(item),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  game.overlays.remove('InventoryOverlay');
                  game.overlays.add('InventoryButton');
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
