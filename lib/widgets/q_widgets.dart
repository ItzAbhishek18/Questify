import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../providers.dart';
import '../theme.dart';

/// Name to show for the signed-in user. Call this from build() only.
String currentDisplayName(WidgetRef ref) {
  final profileName = ref.watch(userProvider)?.displayName?.trim();
  if (profileName != null && profileName.isNotEmpty) return profileName;
  final authName = ref.watch(authProvider).user?.displayName?.trim();
  if (authName != null && authName.isNotEmpty) return authName;
  return 'Adventurer';
}

/// Rounded, bordered card used across all screens.
class QCard extends StatelessWidget {
  const QCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.card,
    this.borderColor = AppColors.border,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: borderColor, width: 1.5),
    );
    return Material(
      color: color,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Small outlined label, e.g. "3 tasks" or "Hard".
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.filled = false});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? AppColors.forest : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.forest),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: filled ? Colors.white : AppColors.forest,
        ),
      ),
    );
  }
}

/// Selectable pill used for filters, categories and difficulty.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.forest),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.forest,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Keeps the decoded picture so it is not decoded again on every rebuild.
String? _cachedPhotoSource;
MemoryImage? _cachedPhoto;

MemoryImage? _photoFor(String? base64Photo) {
  if (base64Photo == null || base64Photo.isEmpty) return null;
  if (base64Photo == _cachedPhotoSource) return _cachedPhoto;
  try {
    _cachedPhoto = MemoryImage(base64Decode(base64Photo));
    _cachedPhotoSource = base64Photo;
    return _cachedPhoto;
  } catch (_) {
    return null;
  }
}

/// The user's profile picture, or their initial when there is no picture.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, this.size = 44, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = currentDisplayName(ref);
    final photo = _photoFor(ref.watch(userProvider)?.photoBase64);

    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.stone,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.forest, width: 2),
        image: photo == null
            ? null
            : DecorationImage(
            image: photo, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
      ),
      child: photo != null
          ? null
          : Text(
        name.characters.first.toUpperCase(),
        style: TextStyle(
          color: AppColors.forest,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
        ),
      ),
    );
    return onTap == null ? avatar : GestureDetector(onTap: onTap, child: avatar);
  }
}

/// "QUESTIFY" label, title, subtitle and avatar, as in the wireframes.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showAvatar = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    Widget? end = trailing;
    if (end == null && showAvatar) {
      end = UserAvatar(onTap: () => context.go(AppRoutes.profile));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QUESTIFY',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (end != null) end,
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.stone),
      ],
    );
  }
}
