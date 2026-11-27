/// Achievements are calculated from stored data only (completed quests,
/// longest streak, level), never from temporary screen state.
class AchievementStats {
  const AchievementStats({
    required this.completedQuests,
    required this.longestStreak,
    required this.level,
  });

  final int completedQuests;
  final int longestStreak;
  final int level;
}

class Achievement {
  Achievement({
    required this.emoji,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });

  final String emoji;
  final String title;
  final String description;
  final bool Function(AchievementStats) isUnlocked;
}

final List<Achievement> allAchievements = [
  Achievement(
    emoji: '🏅',
    title: 'First Steps',
    description: 'Complete your first quest',
    isUnlocked: (s) => s.completedQuests >= 1,
  ),
  Achievement(
    emoji: '📈',
    title: 'Getting Started',
    description: 'Complete five quests',
    isUnlocked: (s) => s.completedQuests >= 5,
  ),
  Achievement(
    emoji: '🔥',
    title: 'Consistency Starter',
    description: 'Complete quests 3 days in a row',
    isUnlocked: (s) => s.longestStreak >= 3,
  ),
  Achievement(
    emoji: '🤓',
    title: 'Dedicated Student',
    description: 'Complete twenty quests',
    isUnlocked: (s) => s.completedQuests >= 20,
  ),
  Achievement(
    emoji: '🏆',
    title: 'Productivity Master',
    description: 'Reach level 5',
    isUnlocked: (s) => s.level >= 5,
  ),
];

String levelTitle(int level) {
  if (level <= 1) return 'Quest Starter';
  if (level <= 3) return 'Quest Explorer';
  if (level <= 6) return 'Quest Adventurer';
  return 'Quest Master';
}
