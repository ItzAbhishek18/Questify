import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/q_widgets.dart';
import '../widgets/quest_tile.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  bool _showActive = true;

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeQuestsProvider);
    final completedAsync = ref.watch(completedQuestsProvider);
    final listAsync = _showActive ? activeAsync : completedAsync;

    final activeList = activeAsync.valueOrNull ?? const [];
    final xpToEarn = activeList.fold<int>(0, (sum, q) => sum + q.xpReward);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const AppHeader(
              title: 'My Quests',
              subtitle: 'Manage your active and completed tasks.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ChoicePill(
                  label: 'Active',
                  selected: _showActive,
                  onTap: () => setState(() => _showActive = true),
                ),
                const SizedBox(width: 10),
                ChoicePill(
                  label: 'Completed',
                  selected: !_showActive,
                  onTap: () => setState(() => _showActive = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            listAsync.when(
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
                if (quests.isEmpty) {
                  return QCard(
                    child: Text(
                      _showActive
                          ? 'No active quests. Add one below.'
                          : 'Nothing completed yet. Finish a quest and it will appear here.',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final q in quests)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: QuestTile(quest: q, showDifficulty: true),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            QCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quest summary',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest)),
                        const SizedBox(height: 4),
                        Text(
                          'Active: ${activeAsync.valueOrNull?.length ?? '-'} · '
                              'Completed: ${completedAsync.valueOrNull?.length ?? '-'}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$xpToEarn XP',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest)),
                      const Text('to earn',
                          style:
                          TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.createQuest),
              icon: const Icon(Icons.add),
              label: const Text('ADD QUEST'),
            ),
          ],
        ),
      ),
    );
  }
}
