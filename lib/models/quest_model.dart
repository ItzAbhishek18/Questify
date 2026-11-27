import 'package:cloud_firestore/cloud_firestore.dart';

/// A quest (goal). Stored at users/{uid}/quests/{id}.
class QuestModel {
  final String id;
  final String title;
  final String description;
  final String? category;
  final DateTime? deadline;
  final String? imageUrl;
  final int targetCount;
  int currentCount;
  final String type; // 'daily', 'weekly', 'monthly', 'one-time'
  final String priority; // 'low', 'medium', 'high'
  final int xpReward;
  final bool xpAwarded;
  final DateTime createdAt;
  DateTime? completedAt;

  QuestModel({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    this.deadline,
    this.imageUrl,
    this.targetCount = 1,
    this.currentCount = 0,
    this.type = 'one-time',
    this.priority = 'medium',
    this.xpReward = 10,
    this.xpAwarded = false,
    required this.createdAt,
    this.completedAt,
  });

  static int _asInt(dynamic value, int fallback) =>
      value is num ? value.toInt() : fallback;

  static DateTime? _asDate(dynamic value) =>
      value is Timestamp ? value.toDate() : null;

  factory QuestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return QuestModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String?,
      deadline: _asDate(data['deadline']),
      imageUrl: data['imageUrl'] as String?,
      targetCount: _asInt(data['targetCount'], 1),
      currentCount: _asInt(data['currentCount'], 0),
      type: data['type'] as String? ?? 'one-time',
      priority: data['priority'] as String? ?? 'medium',
      xpReward: _asInt(data['xpReward'], 10),
      xpAwarded: data['xpAwarded'] as bool? ?? false,
      createdAt: _asDate(data['createdAt']) ?? DateTime.now(),
      completedAt: _asDate(data['completedAt']),
    );
  }

  /// Full document. Use when CREATING a quest.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'imageUrl': imageUrl,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'type': type,
      'priority': priority,
      'xpReward': xpReward,
      'xpAwarded': xpAwarded,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
      completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  /// Only the fields a user may edit. Use when UPDATING a quest, so progress,
  /// completion and XP flags are never overwritten by a stale copy.
  Map<String, dynamic> toEditableFields() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'imageUrl': imageUrl,
      'targetCount': targetCount,
      'type': type,
      'priority': priority,
      'xpReward': xpReward,
    };
  }

  QuestModel copyWith({
    String? title,
    String? description,
    String? category,
    DateTime? deadline,
    String? imageUrl,
    int? targetCount,
    int? currentCount,
    String? type,
    String? priority,
    int? xpReward,
    bool? xpAwarded,
    DateTime? completedAt,
  }) {
    return QuestModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      deadline: deadline ?? this.deadline,
      imageUrl: imageUrl ?? this.imageUrl,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      xpReward: xpReward ?? this.xpReward,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Progress from 0.0 to 1.0.
  double getProgressPercentage() {
    if (targetCount <= 0) return 0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  /// Progress text, e.g. "3/5".
  String getProgressText() => '$currentCount/$targetCount';

  /// A quest is completed when completedAt is set (single source of truth).
  bool get isCompleted => completedAt != null;

  bool get isOverdue =>
      !isCompleted && deadline != null && deadline!.isBefore(DateTime.now());

  String get statusText => isCompleted ? 'Completed!' : 'In Progress';

  /// Readable deadline, e.g. "2d left" or "3d overdue".
  String? get formattedDeadline {
    if (deadline == null) return null;
    final diff = deadline!.difference(DateTime.now());
    final span = diff.abs();

    final String text;
    if (span.inHours < 1) {
      text = 'less than 1h';
    } else if (span.inDays < 1) {
      text = '${span.inHours}h';
    } else if (span.inDays < 7) {
      text = '${span.inDays}d';
    } else if (span.inDays < 30) {
      text = '${span.inDays ~/ 7}w';
    } else {
      text = '${span.inDays ~/ 30}mo';
    }
    return diff.isNegative ? '$text overdue' : '$text left';
  }
}