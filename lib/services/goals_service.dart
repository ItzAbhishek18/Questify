import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:questify/models/quest_model.dart";
import "package:questify/models/user_model.dart";

/// Stores each user quests at users/{uid}/quests/{questId} and awards XP
/// to users/{uid} when a quest is completed.
class GoalsService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GoalsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError("You must be signed in to access quests.");
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _quests =>
      _firestore.collection("users").doc(_uid).collection("quests");

  bool get _signedIn => _auth.currentUser != null;

  Stream<List<QuestModel>> _allQuests() {
    if (!_signedIn) return Stream.value(<QuestModel>[]);
    return _quests
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((s) => s.docs.map(QuestModel.fromFirestore).toList());
  }

  Stream<List<QuestModel>> getQuests() => _allQuests();

  Stream<List<QuestModel>> getActiveQuests() => _allQuests()
      .map((list) => list.where((q) => q.completedAt == null).toList());

  Stream<List<QuestModel>> getCompletedQuests() => _allQuests().map((list) {
    final done = list.where((q) => q.completedAt != null).toList();
    done.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return done;
  });

  Stream<List<QuestModel>> searchQuests(String query) {
    final q = query.toLowerCase();
    return _allQuests().map((list) => list
        .where((quest) =>
    quest.title.toLowerCase().contains(q) ||
        quest.description.toLowerCase().contains(q))
        .toList());
  }

  Future<QuestModel> addQuest(QuestModel quest) async {
    final ref = await _quests.add(quest.toFirestore());
    return QuestModel.fromFirestore(await ref.get());
  }

  /// Updates only the fields a user may edit, so progress, completion and
  /// the XP flag can never be overwritten by a stale copy.
  Future<QuestModel> updateQuest(QuestModel quest) async {
    if (quest.id.isEmpty) {
      throw ArgumentError("Cannot update a quest without an id.");
    }
    final ref = _quests.doc(quest.id);
    await ref.update(quest.toEditableFields());
    return QuestModel.fromFirestore(await ref.get());
  }

  Future<void> deleteQuest(String questId) => _quests.doc(questId).delete();

  static int _asInt(dynamic v) => v is num ? v.toInt() : 0;

  /// Adds progress to a quest. When the quest reaches its target for the
  /// first time, XP, level, streak and quest count are updated in the SAME
  /// transaction. A quest that is already completed is never changed, and
  /// xpAwarded is set once, so XP can never be paid twice.
  Future<QuestModel> incrementProgress({
    required String questId,
    int increment = 1,
  }) async {
    final uid = _uid;
    final questRef = _quests.doc(questId);
    final userRef = _firestore.collection("users").doc(uid);

    final now = DateTime.now();
    final today = UserModel.dateKey(now);
    final yesterday =
    UserModel.dateKey(DateTime(now.year, now.month, now.day - 1));

    await _firestore.runTransaction((tx) async {
      // All reads first, then all writes.
      final questSnap = await tx.get(questRef);
      final userSnap = await tx.get(userRef);
      if (!questSnap.exists) throw Exception("Quest not found");

      final quest = QuestModel.fromFirestore(questSnap);
      if (quest.completedAt != null) return; // already completed

      final newCount =
      (quest.currentCount + increment).clamp(0, quest.targetCount).toInt();
      final reached = newCount >= quest.targetCount;
      final award = reached && !quest.xpAwarded;

      tx.update(questRef, {
        "currentCount": newCount,
        "completedAt": reached ? FieldValue.serverTimestamp() : null,
        if (award) "xpAwarded": true,
      });

      if (award) {
        final data = userSnap.data() ?? <String, dynamic>{};
        final totalXp = _asInt(data["totalXp"]) + quest.xpReward;

        final lastDate = data["lastCompletionDate"] as String?;
        var streak = _asInt(data["currentStreak"]);
        if (lastDate == today) {
          if (streak < 1) streak = 1; // already counted today
        } else if (lastDate == yesterday) {
          streak += 1;
        } else {
          streak = 1;
        }
        final longest =
        streak > _asInt(data["longestStreak"]) ? streak : _asInt(data["longestStreak"]);

        tx.set(
          userRef,
          {
            "totalXp": totalXp,
            "level": UserModel.levelForXp(totalXp),
            "currentStreak": streak,
            "longestStreak": longest,
            "lastCompletionDate": today,
            "questsCompleted": _asInt(data["questsCompleted"]) + 1,
          },
          SetOptions(merge: true),
        );
      }
    });

    return QuestModel.fromFirestore(await questRef.get());
  }

  /// Reopens a quest. xpAwarded stays true, so finishing it again gives no XP.
  Future<QuestModel> resetProgress({required String questId}) async {
    final ref = _quests.doc(questId);
    await ref.update({"currentCount": 0, "completedAt": null});
    return QuestModel.fromFirestore(await ref.get());
  }

  Future<Map<String, int>> getQuestStatistics() async {
    if (!_signedIn) {
      return {"activeQuests": 0, "completedQuests": 0, "totalQuests": 0};
    }
    final snap = await _quests.get();
    final quests = snap.docs.map(QuestModel.fromFirestore).toList();
    final completed = quests.where((q) => q.completedAt != null).length;
    return {
      "activeQuests": quests.length - completed,
      "completedQuests": completed,
      "totalQuests": quests.length,
    };
  }
}

final goalsServiceProvider = Provider((ref) => GoalsService());
