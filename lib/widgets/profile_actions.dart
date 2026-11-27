import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';

/// The dialog owns its text controller, so the controller is disposed only
/// when the dialog is really gone (not while it is still animating out).
class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller =
  TextEditingController(text: widget.initialName);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty');
      return;
    }
    if (name.length > 40) {
      setState(() => _error = 'Use 40 characters or fewer');
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(labelText: 'Full name', errorText: _error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Pass the current name in from build(); this function only uses ref.read.
Future<void> editDisplayName(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    ) async {
  final newName = await showDialog<String>(
    context: context,
    builder: (_) => _EditNameDialog(initialName: currentName),
  );

  if (newName == null || newName == currentName) return;
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    final service = ref.read(authServiceProvider);
    await service.updateProfile(
      displayName: newName,
      photoURL: service.currentUser?.photoURL,
    );
    messenger.showSnackBar(const SnackBar(content: Text('Name updated')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not update name: $e')));
  }
}

/// Lets the user pick a picture from the gallery or remove the current one.
Future<void> changeProfilePhoto(
    BuildContext context,
    WidgetRef ref, {
      required bool hasPhoto,
    }) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(ctx).pop('gallery'),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove photo'),
              onTap: () => Navigator.of(ctx).pop('remove'),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final service = ref.read(profileServiceProvider);

  try {
    if (choice == 'remove') {
      await service.removePhoto();
      messenger.showSnackBar(const SnackBar(content: Text('Photo removed')));
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );
    if (picked == null) return; // the user cancelled

    await service.setPhoto(await picked.readAsBytes());
    messenger.showSnackBar(const SnackBar(content: Text('Profile photo updated')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not update photo: $e')));
  }
}
