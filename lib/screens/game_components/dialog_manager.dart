import 'package:flutter/material.dart';
import 'game_controller.dart';
import 'settings_dialog.dart';
import 'store_dialog.dart';
import 'completion_dialog.dart';
import 'achievement_dialog.dart';
import 'daily_reward_dialog.dart';

/// Manages all game dialogs and popups
class DialogManager {
  final BuildContext context;
  final GameController gameController;

  DialogManager({
    required this.context,
    required this.gameController,
  });

  /// Show completion popup when level is finished
  void showCompletionPopup(VoidCallback onNextLevel) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: CompletionDialog(
            gameController: gameController,
            onNextLevel: onNextLevel,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: false,
      barrierLabel: 'Level complete',
    );
  }

  /// Show settings dialog
  void showSettings(void Function(bool) onSoundToggled, void Function(bool) onVibrationToggled) {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        gameController: gameController,
        onSoundToggled: onSoundToggled,
        onVibrationToggled: onVibrationToggled,
      ),
    );
  }

  /// Show store dialog
  void showStore(VoidCallback onUndoPurchase, VoidCallback onHintPurchase, VoidCallback onCoinPurchase) {
    showDialog(
      context: context,
      builder: (context) => StoreDialog(
        gameController: gameController,
        onUndoPurchase: onUndoPurchase,
        onHintPurchase: onHintPurchase,
        onCoinPurchase: onCoinPurchase,
      ),
    );
  }

  /// Check for daily login rewards
  void checkDailyReward() {
    final dailyReward = gameController.dailyLoginReward;

    if (dailyReward != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DailyRewardDialog(
          gameController: gameController,
          reward: dailyReward,
        ),
      );
    }
  }

  /// Check for pending achievements
  void checkAchievements(bool achievementsChecked, VoidCallback onAchievementShown) {
    if (achievementsChecked) return;

    if (gameController.pendingAchievements.isNotEmpty) {
      // Show achievement dialog for the first achievement
      final achievement = gameController.pendingAchievements.first;

      // Show after a short delay to let level completion dialog close
      Future.delayed(const Duration(milliseconds: 500), () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AchievementDialog(
            gameController: gameController,
            achievement: achievement,
          ),
        ).then((_) => onAchievementShown());
      });
    }
  }

  /// Show dialog when hints are unavailable
  void showHintUnavailableDialog(VoidCallback onGoToStore) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Hints Left!'),
        content: const Text(
          'You have no hints remaining.\n\nYou can earn more hints by:\n'
          '• Completing daily login rewards\n'
          '• Purchasing them in the store\n'
          '• Completing certain achievements',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onGoToStore();
            },
            child: const Text('Go to Store'),
          ),
        ],
      ),
    );
  }

  /// Show error message to the user
  void showErrorPopup(String message) {
    gameController.playSound('error');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[300],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.7,
            left: 20,
            right: 20),
      ),
    );
  }
}