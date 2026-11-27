import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../gamification/achievements.dart';
import '../models/quest_model.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/profile_actions.dart';
import '../widgets/q_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Monday-to-Sunday flags: was at least one quest completed that day?
  List<bool> _weekFlags(List<QuestModel> completed) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return List.generate(7, (i) {
      final d = DateTime(monday.year, monday.month, monday.day + i);
      return completed.any((q) {
        final c = q.completedAt;
        return c != null && c.year == d.year && c.month == d.month && c.day == d.day;
      });
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final authUser = ref.watch(authProvider).user;
    final completed = ref.watch(completedQuestsProvider).valueOrNull ?? const [];

    final name = currentDisplayName(ref);
    final email = authUser?.email ?? user?.email ?? '';
    final level = user?.level ?? 1;
    final hasPhoto = (user?.photoBase64 ?? '').isNotEmpty;
    final stats = AchievementStats(
      completedQuests: completed.length,
      longestStreak: user?.longestStreak ?? 0,
      level: level,
    );
    final week = _weekFlags(completed);
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            AppHeader(
              title: 'My Progress',
              subtitle: 'Your effort, habits and achievements.',
              trailing: IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.forest),
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ),
            const SizedBox(height: 16),
            QCard(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          changeProfilePhoto(context, ref, hasPhoto: hasPhoto),
                      child: Stack(
                        children: [
                          const UserAvatar(size: 96),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.forest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.card, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest)),
                    if (email.isNotEmpty)
                      Text(email,
                          style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 10),
                    Pill('Level $level · ${levelTitle(level)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                      label: 'TOTAL XP', value: '${user?.totalXp ?? 0}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                      label: 'COMPLETED', value: '${completed.length}'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            QCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly consistency',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest)),
                  const SizedBox(height: 2),
                  const Text('Days with at least one completed quest',
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Container(
                          width: 38,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: week[i] ? AppColors.forest : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.forest),
                          ),
                          child: Text(
                            letters[i],
                            style: TextStyle(
                              color: week[i] ? Colors.white : AppColors.forest,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            QCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Achievements',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < allAchievements.length; i++) ...[
                    if (i > 0) const Divider(height: 20),
                    _AchievementLine(
                      achievement: allAchievements[i],
                      unlocked: allAchievements[i].isUnlocked(stats),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => editDisplayName(context, ref, name),
              child: const Text('EDIT PROFILE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return QCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest)),
          ],
        ),
      ),
    );
  }
}

class _AchievementLine extends StatelessWidget {
  const _AchievementLine({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: Row(
        children: [
          Text(achievement.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(achievement.description,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
          Pill(unlocked ? 'Unlocked' : 'Locked', filled: unlocked),
        ],
      ),
    );
  }
}
