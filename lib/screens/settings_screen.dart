import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/profile_actions.dart';
import '../widgets/q_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendPasswordReset(BuildContext context, WidgetRef ref) async {
    final email = ref.read(authServiceProvider).currentUser?.email;
    if (email == null) return;
    try {
      await ref.read(authServiceProvider).resetPassword(email: email);
      if (context.mounted) _snack(context, 'Password reset email sent to $email');
    } catch (e) {
      if (context.mounted) _snack(context, '$e');
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to see your quests.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(authServiceProvider);
    try {
      await NotificationService.instance.unregisterToken();
      await service.signOut(); // the router moves to the login screen
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not sign out: $e')));
    }
  }

  Future<void> _testNow(BuildContext context) async {
    final error = await NotificationService.instance.sendTestNotification();
    if (!context.mounted) return;
    _snack(context, error ?? 'Sent. Check your notification shade.');
  }

  Future<void> _testReminder(BuildContext context) async {
    final error = await NotificationService.instance.scheduleTestReminder();
    if (!context.mounted) return;
    _snack(
      context,
      error ??
          'Reminder scheduled for 30 seconds from now. Lock the screen and wait.',
    );
  }

  Future<void> _status(BuildContext context) async {
    final service = NotificationService.instance;
    final allowed = await service.notificationsAllowed();
    final exact = await service.canScheduleExact();
    final pending = await service.pendingReminderCount();
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reminder status'),
        content: Text(
          'Notifications allowed: ${allowed ? 'yes' : 'NO'}\n'
              'Exact timing allowed: ${exact ? 'yes' : 'no (reminders may be late)'}\n'
              'Reminders waiting: $pending',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(userProvider);
    final authUser = ref.watch(authProvider).user;

    final name = currentDisplayName(ref);
    final email = authUser?.email ?? user?.email ?? '';
    final hasPhoto = (user?.photoBase64 ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        changeProfilePhoto(context, ref, hasPhoto: hasPhoto),
                    child: const UserAvatar(size: 76),
                  ),
                  const SizedBox(height: 12),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(email),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ProfileStat(label: 'Level', value: '${user?.level ?? 1}'),
                      _ProfileStat(label: 'Total XP', value: '${user?.totalXp ?? 0}'),
                      _ProfileStat(
                          label: 'Streak',
                          value: '${user?.effectiveStreak ?? 0} d'),
                      _ProfileStat(
                          label: 'Best', value: '${user?.longestStreak ?? 0} d'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit name'),
                  subtitle: Text(name),
                  onTap: () => editDisplayName(context, ref, name),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Change profile photo'),
                  onTap: () =>
                      changeProfilePhoto(context, ref, hasPhoto: hasPhoto),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Change password'),
                  subtitle: const Text('Send a reset link to your email'),
                  onTap: () => _sendPasswordReset(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                const ListTile(
                  title: Text('Notifications',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Use these to check that reminders work'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Send a test notification now'),
                  onTap: () => _testNow(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm),
                  title: const Text('Test a reminder in 30 seconds'),
                  onTap: () => _testReminder(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: const Text('Check reminder status'),
                  onTap: () => _status(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Questify'),
              subtitle: const Text('Turn your goals into quests.'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Questify',
                applicationVersion: '1.0.0',
                applicationLegalese: 'A gamified student productivity app.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Sign Out', style: TextStyle(color: scheme.error)),
              onTap: () => _signOut(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
