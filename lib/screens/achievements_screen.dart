import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamification/achievements.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/q_widgets.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final completed = ref.watch(completedQuestsProvider).valueOrNull?.length ?? 0;

    final stats = AchievementStats(
      completedQuests: completed,
      longestStreak: user?.longestStreak ?? 0,
      level: user?.level ?? 1,
    );
    final unlockedCount =
        allAchievements.where((a) => a.isUnlocked(stats)).length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const AppHeader(
              title: 'Achievements',
              subtitle: 'Milestones earned through your effort.',
            ),
            const SizedBox(height: 16),
            QCard(
              color: AppColors.stone,
              borderColor: AppColors.forest,
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Unlocked',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest)),
                  ),
                  Text(
                    '$unlockedCount / ${allAchievements.length}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final a in allAchievements)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AchievementRow(
                  achievement: a,
                  unlocked: a.isUnlocked(stats),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: QCard(
        child: Row(
          children: [
            Text(achievement.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(achievement.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(achievement.description,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.muted)),
                ],
              ),
            ),
            Pill(unlocked ? 'Unlocked' : 'Locked', filled: unlocked),
          ],
        ),
      ),
    );
  }
}
