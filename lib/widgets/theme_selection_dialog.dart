import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_theme.dart';
import '../services/theme_service.dart';

class ThemeSelectionDialog extends StatelessWidget {
  const ThemeSelectionDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final currentTheme = themeService.currentTheme;
    
    return Dialog(
      backgroundColor: currentTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: currentTheme.accentColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: currentTheme.headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14.0),
                topRight: Radius.circular(14.0),
              ),
            ),
            child: Text(
              'Choose Theme',
              style: TextStyle(
                color: currentTheme.textColor.withOpacity(0.9),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Select a theme for your game',
              style: TextStyle(
                color: currentTheme.textColor.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: GameTheme.allThemes.length,
              itemBuilder: (context, index) {
                final theme = GameTheme.allThemes[index];
                final isSelected = theme.id == currentTheme.id;
                
                return _ThemeItem(
                  theme: theme,
                  isSelected: isSelected,
                  onSelected: () {
                    themeService.setTheme(theme);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentTheme.buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeItem extends StatelessWidget {
  final GameTheme theme;
  final bool isSelected;
  final VoidCallback onSelected;

  const _ThemeItem({
    Key? key,
    required this.theme,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.accentColor.withOpacity(0.15)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? theme.accentColor
                    : theme.tubeOutlineColor.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Theme preview
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: theme.backgroundGradient,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.tubeOutlineColor),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 30,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: theme.tubeOutlineColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Theme info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.name,
                          style: TextStyle(
                            color: Provider.of<ThemeService>(context).currentTheme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          theme.description,
                          style: TextStyle(
                            color: Provider.of<ThemeService>(context).currentTheme.textColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Selected indicator
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: theme.accentColor,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}