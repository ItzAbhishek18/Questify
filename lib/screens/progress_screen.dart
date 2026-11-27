import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/quest_model.dart';
import '../providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(questsProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: questsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load your stats.\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (quests) => _Content(
          quests: quests,
          totalXp: user?.totalXp ?? 0,
          level: user?.level ?? 1,
          currentStreak: user?.currentStreak ?? 0,
          longestStreak: user?.longestStreak ?? 0,
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.quests,
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
  });

  final List<QuestModel> quests;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int longestStreak;

  /// Quests completed on each of the last 7 days (oldest first).
  List<MapEntry<DateTime, int>> _lastSevenDays() {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, int>>[];
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final count = quests.where((q) {
        final c = q.completedAt;
        return c != null &&
            c.year == day.year &&
            c.month == day.month &&
            c.day == day.day;
      }).length;
      result.add(MapEntry(day, count));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = quests.length;
    final completed = quests.where((q) => q.isCompleted).length;
    final active = total - completed;
    final percent = total == 0 ? 0 : (completed * 100 / total).round();
    final week = _lastSevenDays();
    final weekTotal = week.fold<int>(0, (sum, e) => sum + e.value);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    title: 'Level', value: '$level', color: scheme.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    title: 'Total XP', value: '$totalXp', color: scheme.primary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    title: 'Streak',
                    value: '$currentStreak d',
                    color: scheme.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    title: 'Best streak',
                    value: '$longestStreak d',
                    color: scheme.primary)),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(title: 'Total quests', value: '$total', color: scheme.primary),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    title: 'Active', value: '$active', color: scheme.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    title: 'Completed',
                    value: '$completed',
                    color: scheme.primary)),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Completion rate',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('$percent%',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: scheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : completed / total,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last 7 days: $weekTotal completed',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                _WeekChart(days: week),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days});

  final List<MapEntry<DateTime, int>> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxCount = days.fold<int>(0, (m, e) => e.value > m ? e.value : m);
    const chartHeight = 90.0;

    return SizedBox(
      height: chartHeight + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final entry in days)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${entry.value}', style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(
                    height: maxCount == 0
                        ? 4
                        : (chartHeight * entry.value / maxCount)
                        .clamp(4.0, chartHeight),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: entry.value == 0
                          ? scheme.secondary
                          : scheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(DateFormat.E().format(entry.key),
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}