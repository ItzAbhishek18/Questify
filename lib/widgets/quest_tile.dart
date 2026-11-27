import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/quest_model.dart';
import '../services/goals_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'q_widgets.dart';

String dueLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  return DateFormat.MMMd().format(d);
}

String difficultyLabel(String priority) {
  switch (priority) {
    case 'low':
      return 'Easy';
    case 'high':
      return 'Hard';
    default:
      return 'Medium';
  }
}

/// A quest row with a checkbox. Ticking it completes the quest.
/// Completed quests cannot be un-ticked, so XP can't be earned twice.
class QuestTile extends ConsumerWidget {
  const QuestTile({super.key, required this.quest, this.showDifficulty = false});

  final QuestModel quest;
  final bool showDifficulty;

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final remaining = quest.targetCount - quest.currentCount;
    try {
      await ref.read(goalsServiceProvider).incrementProgress(
        questId: quest.id,
        increment: remaining > 0 ? remaining : 1,
      );
      await NotificationService.instance.cancelQuestReminder(quest.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not complete quest: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parts = <String>[
      if (quest.category != null) quest.category!,
      if (quest.deadline != null) 'Due ${dueLabel(quest.deadline!)}',
      if (quest.targetCount > 1) quest.getProgressText(),
    ];

    return QCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: () => context.push('/quest/${quest.id}'),
      child: Row(
        children: [
          if (quest.isCompleted)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.check_box, color: AppColors.forest),
            )
          else
            Checkbox(
              value: false,
              onChanged: (_) => _complete(context, ref),
              side: const BorderSide(color: AppColors.forest, width: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    decoration:
                    quest.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (parts.isNotEmpty)
                  Text(
                    parts.join(' · '),
                    style: TextStyle(
                      fontSize: 13,
                      color: quest.isOverdue ? AppColors.error : AppColors.muted,
                    ),
                  ),
                if (showDifficulty) ...[
                  const SizedBox(height: 6),
                  Pill(difficultyLabel(quest.priority)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${quest.xpReward} XP',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.forest),
          ),
        ],
      ),
    );
  }
}
