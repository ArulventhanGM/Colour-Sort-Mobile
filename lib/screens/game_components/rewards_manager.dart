import 'package:flutter/material.dart';

/// Class that manages all game rewards and incentives
class RewardsManager {
  // Daily login rewards (coins by day)
  static const Map<int, int> dailyRewards = {
    1: 10, // Day 1: 10 coins
    2: 15, // Day 2: 15 coins
    3: 20, // Day 3: 20 coins
    4: 25, // Day 4: 25 coins
    5: 30, // Day 5: 30 coins + hint
    6: 50, // Day 6: 50 coins (weekend bonus)
  };

  // Achievement definitions
  static final List<Achievement> achievements = [
    Achievement(
      id: 'perfect_level',
      title: 'Perfect Solver',
      description: 'Complete a level using the optimal number of moves',
      coins: 20,
      requiredCount: 1,
    ),
    Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Complete a level in record time',
      coins: 25,
      requiredCount: 1,
    ),
    Achievement(
      id: 'perfect_10',
      title: 'Perfect 10',
      description: 'Complete 10 levels with perfect moves',
      coins: 50,
      requiredCount: 10,
    ),
    Achievement(
      id: 'level_25',
      title: 'Getting Started',
      description: 'Reach level 25',
      coins: 100,
      requiredCount: 1,
    ),
    Achievement(
      id: 'level_50',
      title: 'Halfway There',
      description: 'Reach level 50',
      coins: 200,
      requiredCount: 1,
    ),
    Achievement(
      id: 'level_100',
      title: 'Century Club',
      description: 'Reach level 100',
      coins: 500,
      requiredCount: 1,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Login for 7 days in a row',
      coins: 100,
      requiredCount: 7,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Month Master',
      description: 'Login for 30 days in a row',
      coins: 500,
      requiredCount: 30,
    ),
  ];

  /// Calculate level completion reward
  static LevelReward calculateLevelReward({
    required int levelNumber,
    required int moves,
    required int completionTimeSeconds,
    required int optimalMoves,
  }) {
    // Calculate time thresholds based on level complexity
    int quickTimeThreshold = 15 + (levelNumber * 2); // seconds
    int normalTimeThreshold = 30 + (levelNumber * 3); // seconds

    // Base reward increases with level
    int baseCoins = 10 + (levelNumber * 2);
    int efficiencyBonus = 0;
    int timeBonus = 0;

    // Check if moves were optimal
    bool isOptimalSolution = moves <= optimalMoves;
    if (isOptimalSolution) {
      efficiencyBonus = baseCoins ~/ 2;
    }

    // Check if time was fast
    bool isFastCompletion = completionTimeSeconds <= quickTimeThreshold;
    if (isFastCompletion) {
      timeBonus = baseCoins;
    } else if (completionTimeSeconds <= normalTimeThreshold) {
      timeBonus = baseCoins ~/ 3;
    }

    // Calculate milestone bonus (every 10 levels)
    int milestoneBonus = 0;
    if (levelNumber % 10 == 0) {
      milestoneBonus = levelNumber;
    }

    // Total coins earned
    int totalCoins = baseCoins + efficiencyBonus + timeBonus + milestoneBonus;

    return LevelReward(
      baseCoins: baseCoins,
      efficiencyBonus: efficiencyBonus,
      timeBonus: timeBonus,
      milestoneBonus: milestoneBonus,
      totalCoins: totalCoins,
      isOptimalSolution: isOptimalSolution,
      isFastCompletion: isFastCompletion,
    );
  }

  /// Calculate daily login reward
  static DailyLoginReward calculateDailyLoginReward(int currentStreak) {
    // Get day in cycle (repeats after day 6)
    int dayInCycle = currentStreak % 6;
    if (dayInCycle == 0) dayInCycle = 6;

    // Get coins for this day
    int coins = dailyRewards[dayInCycle] ?? 10;

    // Special reward on day 5
    int hints = dayInCycle == 5 ? 1 : 0;

    return DailyLoginReward(
      day: dayInCycle,
      streak: currentStreak,
      coins: coins,
      hints: hints,
    );
  }

  /// Check for completed achievements based on game state
  static List<Achievement> checkAchievements({
    required int level,
    required int perfectLevelCount,
    required int fastLevelCount,
    required int loginStreak,
    required List<String> completedAchievementIds,
  }) {
    List<Achievement> newlyCompleted = [];

    for (Achievement achievement in achievements) {
      // Skip if already completed
      if (completedAchievementIds.contains(achievement.id)) {
        continue;
      }

      bool completed = false;

      // Check different achievement types
      switch (achievement.id) {
        case 'perfect_level':
          completed = perfectLevelCount >= achievement.requiredCount;
          break;
        case 'speed_demon':
          completed = fastLevelCount >= achievement.requiredCount;
          break;
        case 'perfect_10':
          completed = perfectLevelCount >= achievement.requiredCount;
          break;
        case 'level_25':
          completed = level >= 25;
          break;
        case 'level_50':
          completed = level >= 50;
          break;
        case 'level_100':
          completed = level >= 100;
          break;
        case 'streak_7':
          completed = loginStreak >= 7;
          break;
        case 'streak_30':
          completed = loginStreak >= 30;
          break;
      }

      if (completed) {
        newlyCompleted.add(achievement);
      }
    }

    return newlyCompleted;
  }
}

/// Class representing a level completion reward
class LevelReward {
  final int baseCoins;
  final int efficiencyBonus;
  final int timeBonus;
  final int milestoneBonus;
  final int totalCoins;
  final bool isOptimalSolution;
  final bool isFastCompletion;

  const LevelReward({
    required this.baseCoins,
    required this.efficiencyBonus,
    required this.timeBonus,
    required this.milestoneBonus,
    required this.totalCoins,
    required this.isOptimalSolution,
    required this.isFastCompletion,
  });
}

/// Class representing a daily login reward
class DailyLoginReward {
  final int day;
  final int streak;
  final int coins;
  final int hints;

  const DailyLoginReward({
    required this.day,
    required this.streak,
    required this.coins,
    required this.hints,
  });
}

/// Class representing an achievement
class Achievement {
  final String id;
  final String title;
  final String description;
  final int coins;
  final int requiredCount;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.coins,
    required this.requiredCount,
  });
}
