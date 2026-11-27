import 'package:cloud_firestore/cloud_firestore.dart';

/// A user profile. Stored at users/{uid}.
class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String? photoBase64; // small profile picture, stored in Firestore
  final int questsCompleted;
  final int goalsCompleted;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final String? lastCompletionDate; // 'yyyy-MM-dd' in the user's local time
  final DateTime? createdAt;
  DateTime? lastLogin;

  UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.photoBase64,
    this.questsCompleted = 0,
    this.goalsCompleted = 0,
    this.totalXp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletionDate,
    this.createdAt,
    this.lastLogin,
  });

  // ---- Level rules: the ONLY place that defines them ----------------------

  /// XP needed to finish levels 1, 2, 3, ... (Level 1 needs 100 XP, Level 2
  /// needs 500 XP, Level 3 needs 1500 XP, and so on). Edit the numbers here
  /// to make levelling easier or harder.
  static const List<int> _levelCosts = [100, 500, 1500, 3000, 5000];

  /// Every level after the list above costs this much more than the last.
  static const int _extraLevelStep = 2000;

  /// XP needed to get from [level] to [level] + 1.
  static int xpForLevel(int level) {
    final l = level < 1 ? 1 : level;
    if (l <= _levelCosts.length) return _levelCosts[l - 1];
    return _levelCosts.last + (l - _levelCosts.length) * _extraLevelStep;
  }

  /// The level a user with [xp] total XP is on.
  static int levelForXp(int xp) {
    var level = 1;
    var remaining = xp < 0 ? 0 : xp;
    while (remaining >= xpForLevel(level)) {
      remaining -= xpForLevel(level);
      level++;
    }
    return level;
  }

  /// XP earned inside the current level (what the bar is filled with).
  static int xpIntoLevelFor(int xp) {
    var level = 1;
    var remaining = xp < 0 ? 0 : xp;
    while (remaining >= xpForLevel(level)) {
      remaining -= xpForLevel(level);
      level++;
    }
    return remaining;
  }

  /// "yyyy-MM-dd" for the given local date. Used for streak tracking.
  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  static int _asInt(dynamic value, int fallback) =>
      value is num ? value.toInt() : fallback;

  static DateTime? _asDate(dynamic value) =>
      value is Timestamp ? value.toDate() : null;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final totalXp = _asInt(data['totalXp'], 0);
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoURL: data['photoURL'] as String?,
      photoBase64: data['photoBase64'] as String?,
      questsCompleted: _asInt(data['questsCompleted'], 0),
      goalsCompleted: _asInt(data['goalsCompleted'], 0),
      totalXp: totalXp,
      // Always calculated from total XP, so it can never disagree with it.
      level: levelForXp(totalXp),
      currentStreak: _asInt(data['currentStreak'], 0),
      longestStreak: _asInt(data['longestStreak'], 0),
      lastCompletionDate: data['lastCompletionDate'] as String?,
      createdAt: _asDate(data['createdAt']),
      lastLogin: _asDate(data['lastLogin']),
    );
  }

  /// Profile fields only. XP, level, streaks and the photo are excluded:
  /// they change only through their own dedicated writes.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'questsCompleted': questsCompleted,
      'goalsCompleted': goalsCompleted,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (lastLogin != null) 'lastLogin': Timestamp.fromDate(lastLogin!),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    String? photoBase64,
    int? questsCompleted,
    int? goalsCompleted,
    int? totalXp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    String? lastCompletionDate,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      photoBase64: photoBase64 ?? this.photoBase64,
      questsCompleted: questsCompleted ?? this.questsCompleted,
      goalsCompleted: goalsCompleted ?? this.goalsCompleted,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  /// XP earned so far inside the current level.
  int get xpIntoLevel => xpIntoLevelFor(totalXp);

  /// XP the current level needs in total (the bar's target).
  int get xpForCurrentLevel => xpForLevel(level);

  int get xpToNextLevel => xpForCurrentLevel - xpIntoLevel;

  double get levelProgress => xpIntoLevel / xpForCurrentLevel;

  /// The streak to DISPLAY. The stored streak is only still alive if the last
  /// completion was today or yesterday; otherwise it has already been broken.
  int get effectiveStreak {
    final last = lastCompletionDate;
    if (last == null) return 0;
    final now = DateTime.now();
    final today = dateKey(now);
    final yesterday = dateKey(DateTime(now.year, now.month, now.day - 1));
    return (last == today || last == yesterday) ? currentStreak : 0;
  }
}
