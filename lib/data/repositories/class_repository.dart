// lib/data/repositories/class_repository.dart
import 'dart:io' show File; // mobile/desktop only
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';

import '../models/content_item.dart';
import '../models/live_session.dart';

class ClassRepository {
  final _uuid = const Uuid();
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // ──────────────────────────────
  // Content uploads (two paths)
  // ──────────────────────────────

  /// Upload a local file (Android/iOS/desktop) and return a public download URL.
  Future<String> uploadFileForContent({
    required String category,
    required String filePath,
    String? contentType,
  }) async {
    final id = _uuid.v4();
    final ref = _storage.ref('content/$category/$id${_ext(filePath)}');
    final meta = SettableMetadata(contentType: contentType);
    final snap = await ref.putFile(File(filePath), meta);
    return snap.ref.getDownloadURL();
  }

  /// Upload raw bytes (for Web or when you already have bytes).
  Future<String> uploadBytesForContent({
    required String category,
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final id = _uuid.v4();
    final ref = _storage.ref('content/$category/$id${_ext(filename)}');
    final meta = SettableMetadata(contentType: contentType);
    final snap = await ref.putData(bytes, meta);
    return snap.ref.getDownloadURL();
  }

  String _ext(String pathOrName) {
    final i = pathOrName.lastIndexOf('.');
    return (i >= 0) ? pathOrName.substring(i) : '';
  }

  Future<void> addContent(ContentItem item) async {
    await _db.collection('content').doc(item.id).set(item.toMap());
  }

  Future<List<ContentItem>> contentByCategory(String category) async {
    final q = await _db
        .collection('content')
        .where('category', isEqualTo: category)
        .orderBy('title')
        .get();
    return q.docs.map((d) => ContentItem.fromMap(d.data())).toList();
  }

  // ──────────────────────────────
  // Live sessions
  // ──────────────────────────────

  Future<LiveSession> scheduleLive({
    required String category,
    required String teacherId,
    required String title,
    required DateTime startAt,
    String? zoomUrl,
  }) async {
    final id = _uuid.v4();
    final data = {
      'id': id,
      'category': category,
      'teacherId': teacherId,
      'title': title,
      'startAt': Timestamp.fromDate(startAt),
      'zoomUrl': zoomUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _db.collection('live_sessions').doc(id).set(data);
    return LiveSession(
      id: id,
      category: category,
      teacherId: teacherId,
      title: title,
      startAt: startAt,
      zoomUrl: zoomUrl,
    );
  }

  Future<void> attachZoom(String id, String url) async {
    await _db.collection('live_sessions').doc(id).update({
      'zoomUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Upcoming sessions, ordered ascending by startAt.
  /// If [teacherId] is provided, results are scoped and require an index (see Section 3).
  Future<List<LiveSession>> upcoming(
    String category, {
    String? teacherId,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    Query<Map<String, dynamic>> q = _db
        .collection('live_sessions')
        .where('category', isEqualTo: category)
        .where('startAt', isGreaterThanOrEqualTo: now)
        .orderBy('startAt', descending: false);

    if (teacherId != null) {
      q = q.where('teacherId', isEqualTo: teacherId);
    }
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.limit(limit).get();
    return snap.docs.map(_liveFromDoc).toList();
  }

  /// Previous sessions, ordered descending by startAt (newest first).
  Future<List<LiveSession>> previous(
    String category, {
    String? teacherId,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    Query<Map<String, dynamic>> q = _db
        .collection('live_sessions')
        .where('category', isEqualTo: category)
        .where('startAt', isLessThan: now)
        .orderBy('startAt', descending: true);

    if (teacherId != null) {
      q = q.where('teacherId', isEqualTo: teacherId);
    }
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.limit(limit).get();
    return snap.docs.map(_liveFromDoc).toList();
  }

  LiveSession _liveFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return LiveSession(
      id: m['id'] as String,
      category: m['category'] as String,
      teacherId: m['teacherId'] as String,
      title: m['title'] as String,
      startAt: (m['startAt'] as Timestamp).toDate(),
      zoomUrl: m['zoomUrl'] as String?,
    );
  }
}
