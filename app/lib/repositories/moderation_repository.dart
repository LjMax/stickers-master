import 'package:cloud_firestore/cloud_firestore.dart';

/// One entry in the signed-in user's block list. The display name and
/// photo are denormalised into the block doc at block time so the
/// "Blocked users" screen can render without extra profile reads.
class BlockEntry {
  const BlockEntry({
    required this.blockedUid,
    required this.blockedName,
    this.blockedPhotoUrl,
    this.createdAt,
  });

  final String blockedUid;
  final String blockedName;
  final String? blockedPhotoUrl;
  final DateTime? createdAt;

  factory BlockEntry.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return BlockEntry(
      blockedUid: data['blocked'] as String? ?? '',
      blockedName: data['blocked_name'] as String? ?? '',
      blockedPhotoUrl: data['blocked_photo'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}

/// All Firestore reads/writes for moderation: blocking users and filing
/// abuse reports.
class ModerationRepository {
  ModerationRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _db.collection('blocks');

  /// Deterministic block doc id. One block doc per (blocker, blocked) pair.
  String _blockId(String blocker, String blocked) => '${blocker}_$blocked';

  /// [blockerUid] blocks [blockedUid]. Idempotent — re-blocking just
  /// rewrites the same doc. Name/photo are stored so the blocked-users
  /// list can render without a profile lookup.
  Future<void> blockUser({
    required String blockerUid,
    required String blockedUid,
    String? blockedName,
    String? blockedPhotoUrl,
  }) async {
    if (blockerUid == blockedUid) return;
    await _blocks.doc(_blockId(blockerUid, blockedUid)).set({
      'blocker': blockerUid,
      'blocked': blockedUid,
      'blocked_name': blockedName ?? '',
      if (blockedPhotoUrl != null && blockedPhotoUrl.isNotEmpty)
        'blocked_photo': blockedPhotoUrl,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Remove the block [blockerUid] placed on [blockedUid].
  Future<void> unblockUser({
    required String blockerUid,
    required String blockedUid,
  }) async {
    await _blocks.doc(_blockId(blockerUid, blockedUid)).delete();
  }

  /// Stream of uids that [uid] has blocked.
  Stream<Set<String>> watchBlockedByMe(String uid) {
    return _blocks.where('blocker', isEqualTo: uid).snapshots().map((q) {
      return q.docs
          .map((d) => d.data()['blocked'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
    });
  }

  /// Stream of uids that have blocked [uid].
  Stream<Set<String>> watchWhoBlockedMe(String uid) {
    return _blocks.where('blocked', isEqualTo: uid).snapshots().map((q) {
      return q.docs
          .map((d) => d.data()['blocker'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
    });
  }

  /// Stream of full block entries for [uid] (for the "Blocked users"
  /// screen), newest first.
  Stream<List<BlockEntry>> watchMyBlockEntries(String uid) {
    return _blocks.where('blocker', isEqualTo: uid).snapshots().map((q) {
      final list = q.docs.map(BlockEntry.fromDoc).toList();
      list.sort((a, b) {
        final aT = a.createdAt ?? DateTime(0);
        final bT = b.createdAt ?? DateTime(0);
        return bT.compareTo(aT);
      });
      return list;
    });
  }

  /// File an abuse report. Reports are write-only from the client and
  /// reviewed via the Firebase Console.
  Future<void> submitReport({
    required String reporterUid,
    required String reportedUid,
    required String reason,
    String? chatId,
    String? details,
  }) async {
    await _db.collection('reports').add({
      'reporter': reporterUid,
      'reported_user': reportedUid,
      'reason': reason,
      if (chatId != null && chatId.isNotEmpty) 'chat_id': chatId,
      if (details != null && details.trim().isNotEmpty)
        'details': details.trim(),
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
