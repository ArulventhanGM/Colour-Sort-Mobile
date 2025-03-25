import 'package:flutter/material.dart';
import 'game_controller.dart';
import 'hint_manager.dart';

/// Manages hint animations and interactions
class HintAnimationController {
  final GameController gameController;
  final AnimationController hintController;
  final void Function(String) showErrorPopup;
  
  // Hint animation state
  bool showingHintAnimation = false;
  Offset? hintFromPosition;
  Offset? hintToPosition;
  HintMove? currentHintMove;

  HintAnimationController({
    required this.gameController,
    required this.hintController,
    required this.showErrorPopup,
  });

  /// Show hint for the next best move
  void showHint(BuildContext context, void Function(void Function()) setState, VoidCallback showHintUnavailableDialog) {
    // First check if we have any hints left
    if (gameController.hints <= 0) {
      showHintUnavailableDialog();
      return;
    }

    // Get a hint move from the game controller
    final hintMove = gameController.useHint();
    
    if (hintMove == null) {
      showErrorPopup("No valid moves found! Try adding a tube or restarting.");
      return;
    }

    // Find the source and destination tube positions for the animation
    final fromTube = hintMove.fromTube;
    final toTube = hintMove.toTube;
    
    currentHintMove = hintMove;

    // Get positions of the tubes for the animation
    if (gameController.tubeKeys[fromTube] == null || 
        gameController.tubeKeys[toTube] == null) {
      showErrorPopup("Cannot show hint right now. Try again later.");
      return;
    }

    final sourceContext = gameController.tubeKeys[fromTube]!.currentContext;
    final targetContext = gameController.tubeKeys[toTube]!.currentContext;

    if (sourceContext == null || targetContext == null) {
      showErrorPopup("Cannot show hint right now. Try again later.");
      return;
    }

    final sourceRenderBox = sourceContext.findRenderObject() as RenderBox?;
    final targetRenderBox = targetContext.findRenderObject() as RenderBox?;

    if (sourceRenderBox == null || targetRenderBox == null) {
      showErrorPopup("Cannot show hint right now. Try again later.");
      return;
    }

    // Calculate center points of tubes for arrow
    final sourcePosition = sourceRenderBox.localToGlobal(Offset.zero);
    final targetPosition = targetRenderBox.localToGlobal(Offset.zero);

    final sourceCenter = Offset(
      sourcePosition.dx + sourceRenderBox.size.width / 2,
      sourcePosition.dy + sourceRenderBox.size.height * 0.25,
    );

    final targetCenter = Offset(
      targetPosition.dx + targetRenderBox.size.width / 2,
      targetPosition.dy + targetRenderBox.size.height * 0.25,
    );

    // Store these positions for the hint animation
    hintFromPosition = sourceCenter;
    hintToPosition = targetCenter;

    // Show hint animation
    setState(() {
      showingHintAnimation = true;
      gameController.playSound('select');
    });

    // Start the animation
    hintController.forward(from: 0);

    // Highlight the tubes involved
    _highlightHintTubes(fromTube, toTube);

    // Hide the hint automatically after some time
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        showingHintAnimation = false;
        hintFromPosition = null;
        hintToPosition = null;
        currentHintMove = null;
      });
    });
  }

  /// Highlight the tubes involved in a hint
  void _highlightHintTubes(int fromTube, int toTube) {
    // This could be implemented to add visual highlighting to the tubes
    // Currently using the arrow visual as the main hint
  }
  
  void reset() {
    showingHintAnimation = false;
    hintFromPosition = null;
    hintToPosition = null;
    currentHintMove = null;
  }
}