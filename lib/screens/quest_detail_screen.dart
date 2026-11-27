import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/quest_model.dart';
import '../providers.dart';
import '../services/goals_service.dart';

class QuestDetailScreen extends ConsumerStatefulWidget {
  final String questId;

  const QuestDetailScreen({required this.questId, super.key});

  @override
  ConsumerState<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends ConsumerState<QuestDetailScreen> {
  static const _baseCategories = [
    'Study',
    'Assignment',
    'Exam',
    'Personal',
    'Health',
  ];
  static const _xpByPriority = {'low': 10, 'medium': 20, 'high': 30};

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetCountController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  String? _category;
  String _priority = 'medium';
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetCountController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startEditing(QuestModel quest) {
    _titleController.text = quest.title;
    _descriptionController.text = quest.description;
    _targetCountController.text = quest.targetCount.toString();
    _category = quest.category;
    _priority = _xpByPriority.containsKey(quest.priority)
        ? quest.priority
        : 'medium';
    _deadline = quest.deadline;
    setState(() => _isEditing = true);
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = (_deadline != null && _deadline!.isAfter(now))
        ? _deadline!
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _deadline =
          DateTime(picked.year, picked.month, picked.day, 23, 59));
    }
  }

  Future<void> _saveQuest(QuestModel quest) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      // Keep every field we are not editing exactly as stored.
      final updated = QuestModel(
        id: quest.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        deadline: _deadline,
        imageUrl: quest.imageUrl,
        targetCount: quest.isCompleted
            ? quest.targetCount
            : int.parse(_targetCountController.text.trim()),
        currentCount: quest.currentCount,
        type: quest.type,
        priority: _priority,
        xpReward: _xpByPriority[_priority]!,
        xpAwarded: quest.xpAwarded,
        createdAt: quest.createdAt,
        completedAt: quest.completedAt,
      );
      await ref.read(goalsServiceProvider).updateQuest(updated);
      if (mounted) setState(() => _isEditing = false);
      _showMessage('Quest updated');
    } catch (e) {
      _showMessage('Could not save quest: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteQuest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete quest?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(goalsServiceProvider).deleteQuest(widget.questId);
      if (mounted) context.pop();
    } catch (e) {
      _showMessage('Could not delete quest: $e');
    }
  }

  Future<void> _advance(QuestModel quest, {int? by}) async {
    try {
      await ref
          .read(goalsServiceProvider)
          .incrementProgress(questId: quest.id, increment: by ?? 1);
    } catch (e) {
      _showMessage('Could not update quest: $e');
    }
  }

  Scaffold _plain(String title, Widget body) =>
      Scaffold(appBar: AppBar(title: Text(title)), body: body);

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(questsProvider);

    return questsAsync.when(
      loading: () => _plain(
        'Quest Details',
        const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _plain(
        'Quest Details',
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load quest.\n$e', textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (quests) {
        QuestModel? quest;
        for (final q in quests) {
          if (q.id == widget.questId) {
            quest = q;
            break;
          }
        }
        if (quest == null) {
          return _plain(
            'Quest Details',
            const Center(child: Text('Quest not found.')),
          );
        }
        final current = quest;

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Quest' : current.title),
            actions: [
              IconButton(
                tooltip: _isEditing ? 'Cancel editing' : 'Edit',
                icon: Icon(_isEditing ? Icons.close : Icons.edit),
                onPressed: _isEditing
                    ? () => setState(() => _isEditing = false)
                    : () => _startEditing(current),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.delete,
                    color: Theme.of(context).colorScheme.error),
                onPressed: _deleteQuest,
              ),
            ],
          ),
          body: _isEditing ? _buildEditForm(current) : _buildViewMode(current),
        );
      },
    );
  }

  Widget _buildViewMode(QuestModel quest) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final remaining = quest.targetCount - quest.currentCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(quest.title, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text(quest.isCompleted ? 'Completed' : 'In progress'),
              backgroundColor: quest.isCompleted
                  ? scheme.primaryContainer
                  : scheme.secondaryContainer,
            ),
            if (quest.category != null) Chip(label: Text(quest.category!)),
            Chip(label: Text('${quest.priority} priority')),
            Chip(label: Text('${quest.xpReward} XP')),
          ],
        ),
        const SizedBox(height: 16),
        if (quest.description.isNotEmpty) ...[
          Text(quest.description),
          const SizedBox(height: 16),
        ],
        if (quest.deadline != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.event,
                color: quest.isOverdue ? scheme.error : scheme.primary),
            title: Text('Due ${DateFormat.yMMMd().format(quest.deadline!)}'),
            subtitle: Text(
              quest.formattedDeadline ?? '',
              style: TextStyle(color: quest.isOverdue ? scheme.error : null),
            ),
          ),
        const SizedBox(height: 8),
        Text('Progress: ${quest.getProgressText()}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: quest.getProgressPercentage(),
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
        if (quest.completedAt != null) ...[
          const SizedBox(height: 8),
          Text('Completed ${DateFormat.yMMMd().add_jm().format(quest.completedAt!)}'),
        ],
        const SizedBox(height: 24),
        if (!quest.isCompleted) ...[
          if (quest.targetCount > 1) ...[
            OutlinedButton.icon(
              onPressed: () => _advance(quest),
              icon: const Icon(Icons.add),
              label: const Text('Add progress (+1)'),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: () => _advance(quest, by: remaining),
            icon: const Icon(Icons.check),
            label: const Text('Complete quest'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ],
    );
  }

  Widget _buildEditForm(QuestModel quest) {
    final categories = <String>[
      ..._baseCategories,
      if (quest.category != null && !_baseCategories.contains(quest.category))
        quest.category!,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'low', label: Text('Low')),
                ButtonSegment(value: 'medium', label: Text('Medium')),
                ButtonSegment(value: 'high', label: Text('High')),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 8),
            Text('Reward: ${_xpByPriority[_priority]} XP'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetCountController,
              enabled: !quest.isCompleted,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Times to complete (1-100)',
                helperText: quest.isCompleted
                    ? 'Locked because this quest is completed'
                    : null,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (quest.isCompleted) return null;
                final n = int.tryParse((v ?? '').trim());
                if (n == null) return 'Enter a number';
                if (n < 1 || n > 100) return 'Use a number from 1 to 100';
                if (n <= quest.currentCount && quest.currentCount > 0) {
                  return 'Must be higher than current progress '
                      '(${quest.currentCount})';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDeadline,
              icon: const Icon(Icons.event),
              label: Text(_deadline == null
                  ? 'Set deadline (optional)'
                  : 'Deadline: ${DateFormat.yMMMd().format(_deadline!)}'),
            ),
            if (_deadline != null)
              TextButton(
                onPressed: () => setState(() => _deadline = null),
                child: const Text('Remove deadline'),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving ? null : () => _saveQuest(quest),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}