import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import 'q_widgets.dart';

/// Asks for a new display name and saves it to Firebase Auth and Firestore.
Future<void> editDisplayName(BuildContext context, WidgetRef ref) async {
  final current = currentDisplayName(ref);
  final controller = TextEditingController(text: current);
  final newName = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit name'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Full name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();

  if (newName == null || newName.isEmpty || newName == current) return;

  try {
    final service = ref.read(authServiceProvider);
    await service.updateProfile(
      displayName: newName,
      photoURL: service.currentUser?.photoURL,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name updated')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not update name: $e')));
    }
  }
}
