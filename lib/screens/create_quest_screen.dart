import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/quest_model.dart';
import '../services/goals_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/q_widgets.dart';

class CreateQuestScreen extends ConsumerStatefulWidget {
  const CreateQuestScreen({super.key});

  @override
  ConsumerState<CreateQuestScreen> createState() => _CreateQuestScreenState();
}

class _CreateQuestScreenState extends ConsumerState<CreateQuestScreen> {
  static const _categories = ['Academic', 'Personal'];
  // difficulty (stored as priority) -> label and XP reward
  static const _difficulties = {
    'low': ('Easy', 25),
    'medium': ('Medium', 50),
    'high': ('Hard', 100),
  };

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = _categories.first;
  String _difficulty = 'medium';
  DateTime? _deadline;
  TimeOfDay? _reminderTime;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _deadline =
          DateTime(picked.year, picked.month, picked.day, 23, 59));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  String _friendlyError(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Firebase denied saving this quest. Publish the Firestore rules '
          'that allow users/{your uid}/quests, then try again.';
    }
    if (e is FirebaseException && e.code == 'unavailable') {
      return 'No connection to Firebase. Check your internet and try again.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  /// Reminder moment: on the due date (or today if there is none) at the
  /// chosen time. With no due date, a time already passed means tomorrow.
  DateTime? _reminderMoment() {
    final t = _reminderTime;
    if (t == null) return null;
    final now = DateTime.now();
    final base = _deadline ?? now;
    var moment = DateTime(base.year, base.month, base.day, t.hour, t.minute);
    if (!moment.isAfter(now) && _deadline == null) {
      moment = moment.add(const Duration(days: 1));
    }
    return moment;
  }

  Future<void> _saveQuest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final reminder = _reminderMoment();
    if (reminder != null && !reminder.isAfter(DateTime.now())) {
      setState(() => _errorMessage =
      'The reminder time is already in the past. Pick a later time or date.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final (_, xp) = _difficulties[_difficulty]!;
      final saved = await ref.read(goalsServiceProvider).addQuest(
        QuestModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          deadline: _deadline,
          priority: _difficulty,
          xpReward: xp,
          createdAt: DateTime.now(),
        ),
      );

      final notifications = NotificationService.instance;
      if (reminder != null) {
        await notifications.scheduleQuestReminder(
          questId: saved.id,
          questTitle: saved.title,
          when: reminder,
        );
      } else if (_deadline != null) {
        await notifications.scheduleDeadlineReminder(
          questId: saved.id,
          questTitle: saved.title,
          deadline: _deadline!,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Quest created')));
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.forest),
    ),
  );

  Widget _tapField({
    required String text,
    required bool isPlaceholder,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(suffixIcon: Icon(icon, size: 20)),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: isPlaceholder ? AppColors.muted : AppColors.text,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeader(
                title: 'Create a Quest',
                subtitle: 'Break a goal into a clear next action.',
                showAvatar: false,
              ),
              const SizedBox(height: 16),
              QCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Quest title *'),
                      TextFormField(
                        controller: _titleController,
                        maxLength: 80,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Review lecture notes',
                          counterText: '',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                      ),
                      _label('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          hintText: 'What do you need to do?',
                          counterText: '',
                        ),
                      ),
                      _label('Category *'),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final c in _categories)
                            ChoicePill(
                              label: c,
                              selected: _category == c,
                              onTap: () => setState(() => _category = c),
                            ),
                        ],
                      ),
                      _label('Due date'),
                      _tapField(
                        text: _deadline == null
                            ? 'Choose date'
                            : DateFormat.yMMMd().format(_deadline!),
                        isPlaceholder: _deadline == null,
                        icon: Icons.calendar_today_outlined,
                        onTap: _pickDate,
                      ),
                      if (_deadline != null)
                        TextButton(
                          onPressed: () => setState(() => _deadline = null),
                          child: const Text('Remove due date'),
                        ),
                      _label('Reminder'),
                      _tapField(
                        text: _reminderTime == null
                            ? 'Select time'
                            : _reminderTime!.format(context),
                        isPlaceholder: _reminderTime == null,
                        icon: Icons.access_time,
                        onTap: _pickTime,
                      ),
                      if (_reminderTime != null)
                        TextButton(
                          onPressed: () =>
                              setState(() => _reminderTime = null),
                          child: const Text('Remove reminder'),
                        ),
                      _label('Difficulty'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in _difficulties.entries)
                            ChoicePill(
                              label:
                              '${entry.value.$1} · ${entry.value.$2} XP',
                              selected: _difficulty == entry.key,
                              onTap: () =>
                                  setState(() => _difficulty = entry.key),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isLoading ? null : _saveQuest,
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Text('SAVE QUEST'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: const Text('CANCEL'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
