// lib/data/repositories/admin_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- Helpers ----------------
  Future<int> _count(Query<Map<String, dynamic>> q) async {
    try {
      final snap = await q.count().get();
      return snap.count ?? 0;
    } on FirebaseException {
      return (await q.limit(1000).get()).size;
    } catch (_) {
      return 0;
    }
  }

  bool _isApprovedValue(Object? v) {
    if (v == null) return false;
    if (v == true) return true;
    if (v is num && v.toInt() == 1) return true;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == 'approved';
    }
    return false;
  }

  bool _isBlockedValue(Object? v) {
    if (v == null) return false;
    if (v is num && v.toInt() == -1) return true;
    if (v is String) return v.trim().toLowerCase() == 'blocked';
    return false;
  }

  bool _isPendingValue(Object? v) {
    // pending = not approved and not blocked (null/false/0/"false")
    return !_isApprovedValue(v) && !_isBlockedValue(v);
  }

  int _asMillis(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    return 0;
  }

  AppUser _toUser(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? const <String, dynamic>{};
    return AppUser.fromMap(<String, dynamic>{...data, 'id': d.id});
  }

  // ---------------- KPIs ----------------
  Future<Map<String, int>> summary() async {
    try {
      final teachers = await _count(
        _db.collection('users').where('role', isEqualTo: 'teacher'),
      );
      final students = await _count(
        _db.collection('users').where('role', isEqualTo: 'student'),
      );

      // Robust pending count (handles bool/int/string/missing)
      final teachersSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();
      final pending = teachersSnap.docs
          .where((d) => _isPendingValue(d.data()['isApproved']))
          .length;

      Future<int> safeCount(String col) async {
        try {
          return await _count(_db.collection(col));
        } catch (_) {
          return 0;
        }
      }

      final content = await safeCount('content');
      final live = await safeCount('live_sessions');
      final tests = await safeCount('test_papers');

      return {
        'teachers': teachers,
        'pending': pending,
        'students': students,
        'content': content,
        'live': live,
        'tests': tests,
      };
    } catch (_) {
      return {
        'teachers': 0,
        'pending': 0,
        'students': 0,
        'content': 0,
        'live': 0,
        'tests': 0,
      };
    }
  }

  // ---------------- Lists ----------------
  Future<List<AppUser>> pendingTeachers() async {
    try {
      // No orderBy here (avoids composite index requirement).
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();

      final items = snap.docs
          .where((d) => _isPendingValue(d.data()['isApproved']))
          .map(_toUser)
          .toList();

      items
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<List<AppUser>> approvedTeachers(
      {String? q, String? categoryOrSpec}) async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();

      final search = (q ?? '').toLowerCase();
      final spec = (categoryOrSpec ?? '').toLowerCase();

      final list = snap.docs
          .where((d) => _isApprovedValue(d.data()['isApproved'])) // robust
          .map(_toUser)
          .where((u) {
        final inQ = search.isEmpty ||
            u.name.toLowerCase().contains(search) ||
            (u.email?.toLowerCase().contains(search) ?? false) ||
            (u.phone?.toLowerCase().contains(search) ?? false);
        final inSpec =
            spec.isEmpty || (u.specialty ?? '').toLowerCase().contains(spec);
        return inQ && inSpec;
      }).toList();

      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    } catch (_) {
      return const [];
    }
  }

  Future<List<AppUser>> students({String? q}) async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final search = (q ?? '').toLowerCase();
      final list = snap.docs
          .map(_toUser)
          .where((u) =>
              search.isEmpty ||
              u.name.toLowerCase().contains(search) ||
              (u.email?.toLowerCase().contains(search) ?? false) ||
              (u.college?.toLowerCase().contains(search) ?? false))
          .toList();

      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    } catch (_) {
      return const [];
    }
  }

  // ---------------- Stats per teacher ----------------
  Future<Map<String, int>> teacherStats(String teacherId) async {
    Future<int> c(String col) async {
      try {
        return await _count(
          _db.collection(col).where('teacherId', isEqualTo: teacherId),
        );
      } catch (_) {
        return 0;
      }
    }

    return {
      'content': await c('content'),
      'live': await c('live_sessions'),
      'tests': await c('test_papers'),
    };
  }

  // ---------------- Mutations ----------------
  Future<void> approveTeacher(String teacherId) async {
    await _db.collection('users').doc(teacherId).update({'isApproved': true});
  }

  Future<void> blockUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isApproved': -1});
  }

  Future<void> promoteToAdmin(String userId) async {
    await _db.collection('users').doc(userId).update({
      'role': 'admin',
      'isApproved': true,
    });
  }

  // ---------------- Notifications ----------------
  Future<void> createNotification({
    required String title,
    required String message,
    String targetRole = 'all',
    String? category,
  }) async {
    await _db.collection('notifications').add({
      'title': title,
      'message': message,
      'targetRole': targetRole,
      'category': (category?.trim().isEmpty ?? true) ? null : category!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, Object?>>> listNotifications() async {
    try {
      final snap = await _db
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map((d) {
        final data = d.data();
        return <String, Object?>{
          'id': d.id,
          ...data,
          'createdAt': _asMillis(data['createdAt']),
        };
      }).toList();
    } catch (_) {
      return const [];
    }
  }
}
