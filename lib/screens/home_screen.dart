import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../models/quest_model.dart';
import '../models/user_model.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/q_widgets.dart';
import '../widgets/quest_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Quests due today, overdue, or without a deadline (max 5).
  List<QuestModel> _today(List<QuestModel> active) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final list = active
        .where((q) => q.deadline == null || !q.deadline!.isAfter(endOfToday))
        .toList();
    list.sort((a, b) {
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });
    return list.take(5).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeQuestsProvider);
    final user = ref.watch(userProvider);
    final firstName = currentDisplayName(ref).split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            AppHeader(
              title: 'Hello, $firstName!',
              subtitle: "Ready for today's quests?",
            ),
            const SizedBox(height: 16),
            _LevelCard(user: user),
            const SizedBox(height: 24),
            activeAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not load quests.\n$e',
                    textAlign: TextAlign.center),
              ),
              data: (quests) {
                final today = _today(quests);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Today's Quests",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                        Pill('${today.length} task${today.length == 1 ? '' : 's'}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (today.isEmpty)
                      const QCard(
                        child: Text(
                          'Nothing due today. Create a quest to get started.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    else
                      for (final q in today)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: QuestTile(quest: q),
                        ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.createQuest),
              icon: const Icon(Icons.add),
              label: const Text('CREATE QUEST'),
            ),
            const SizedBox(height: 14),
            QCard(
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current streak',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest)),
                        SizedBox(height: 4),
                        Text('Keep showing up each day.',
                            style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text(
                    '🔥 ${user?.effectiveStreak ?? 0}',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final level = user?.level ?? 1;
    final into = user?.xpIntoLevel ?? 0;
    final needed = user?.xpForCurrentLevel ?? UserModel.xpForLevel(1);
    final toNext = needed - into;
    final progress = user?.levelProgress ?? 0.0;

    return QCard(
      color: AppColors.stone,
      borderColor: AppColors.forest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CURRENT LEVEL',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    Text(
                      'Level ${level.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('XP PROGRESS',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  Text(
                    '$into / $needed',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 8),
          Text('$toNext XP until your next level',
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        ],
      ),
    );
  }
}
