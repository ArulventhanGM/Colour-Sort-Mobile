import 'package:flutter/material.dart';
import 'game_controller.dart';

/// Dialog for the in-game store
class StoreDialog extends StatelessWidget {
  final GameController gameController;
  final VoidCallback onUndoPurchase;
  final VoidCallback onHintPurchase;
  final VoidCallback onCoinPurchase;

  const StoreDialog({
    Key? key,
    required this.gameController,
    required this.onUndoPurchase,
    required this.onHintPurchase,
    required this.onCoinPurchase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Store'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.arrow_back, color: Colors.blue),
            title: const Text('10 Undo Moves'),
            subtitle: const Text('Never get stuck again'),
            trailing: ElevatedButton(
              onPressed: () {
                onUndoPurchase();
                Navigator.of(context).pop();
              },
              child: const Text('30 🪙'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb, color: Colors.amber),
            title: const Text('5 Hints'),
            subtitle: const Text('Get unstuck with smart suggestions'),
            trailing: ElevatedButton(
              onPressed: () {
                onHintPurchase();
                Navigator.of(context).pop();
              },
              child: const Text('20 🪙'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on, color: Colors.orange),
            title: const Text('100 Coins'),
            subtitle: const Text('Currency pack'),
            trailing: ElevatedButton(
              onPressed: () {
                onCoinPurchase();
                Navigator.of(context).pop();
              },
              child: const Text('\$1.99'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
