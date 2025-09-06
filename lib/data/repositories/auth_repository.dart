// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class AuthRepository {
  static const _kSessionUserId = 'session_user_id';
  final _auth = fb.FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  AuthRepository() {
    // Offline persistence is enabled by default on mobile; this keeps parity.
    _db.settings = const Settings(persistenceEnabled: true);
  }

  /* ─────────── Session ─────────── */

  Future<AppUser?> currentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final map = doc.data()!..['id'] = user.uid;
    final appUser = AppUser.fromMap(map);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionUserId, appUser.id);
    return appUser;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionUserId);
    await _auth.signOut();
  }

  /* ─────────── Registration ─────────── */

  Future<AppUser> registerStudent({
    required String name,
    required String email,
    required String phone,
    required int age,
    required String college,
    required String standard,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    final u = AppUser(
      id: uid,
      role: 'student',
      name: name,
      email: email,
      phone: phone,
      age: age,
      college: college,
      standard: standard,
      isApproved: true,
    );
    await _db.collection('users').doc(uid).set(u.toMap());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionUserId, uid);
    return u;
  }

  Future<AppUser> registerTeacher({
    required String name,
    required String email,
    required String phone,
    required String specialty,
    String? about,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    final u = AppUser(
      id: uid,
      role: 'teacher',
      name: name,
      email: email,
      phone: phone,
      specialty: specialty,
      about: about,
      isApproved: false,
    );
    await _db.collection('users').doc(uid).set(u.toMap());
    return u;
  }

  /* ─────────── Sign in ─────────── */

  Future<AppUser?> signInEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final map = doc.data()!..['id'] = uid;
    final u = AppUser.fromMap(map);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionUserId, u.id);
    return u;
  }

  /* ─────────── Admin helpers ─────────── */

  Future<List<AppUser>> pendingTeachers() async {
    final q = await _db
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .where('isApproved', isEqualTo: false)
        .get();
    return q.docs
        .map((d) => AppUser.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  Future<void> approveTeacher(String teacherId) async {
    await _db.collection('users').doc(teacherId).update({'isApproved': true});
  }

  /* ─────────── Profile updates ─────────── */

  Future<void> updateStudentProfile({
    required String id,
    required String name,
    required String phone,
    required int age,
    required String college,
    required String standard,
  }) async {
    String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();
    await _db.collection('users').doc(id).update({
      'name': name.trim(),
      'phone': _nullIfEmpty(phone),
      'age': age,
      'college': _nullIfEmpty(college),
      'standard': _nullIfEmpty(standard),
    });
  }

  /// Change password with old-password verification (reauthenticate required).
  Future<bool> changePassword({
    required String id,
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != id || user.email == null) return false;

    final cred = fb.EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Update email in Auth + Firestore using the **new** API.
  /// NOTE:
  /// - Firebase requires recent login. Pass `currentPassword` to re-auth.
  /// - This sends a verification link to the *new* email. The Auth email
  ///   switches only after the user clicks the link.
  /// Update email in Auth + Firestore using the new API (positional ActionCodeSettings).
  Future<bool> updateEmail({
    required String id,
    required String email,
    String? currentPassword, // for reauth with email/password
    String? continueUrl, // optional deep link after verification
  }) async {
    final fb.User? user = _auth.currentUser;
    if (user == null || user.uid != id) return false;

    try {
      // Re-authenticate if we can (prevents "requires-recent-login").
      if (user.email != null &&
          currentPassword != null &&
          currentPassword.isNotEmpty) {
        final cred = fb.EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(cred);
      }

      // Build ActionCodeSettings if you want a deep link after confirm.
      fb.ActionCodeSettings? acs;
      if (continueUrl != null && continueUrl.isNotEmpty) {
        acs = fb.ActionCodeSettings(
          url: continueUrl,
          handleCodeInApp: true,
          androidPackageName:
              'com.example.skillseed_app', // TODO: replace with yours
          androidInstallApp: true,
          androidMinimumVersion: '21',
          iOSBundleId: 'com.example.skillseedApp', // TODO: replace with yours
        );
      }

      // NOTE: second parameter is positional (NOT named) on your version.
      if (acs != null) {
        await user.verifyBeforeUpdateEmail(email.trim(), acs);
      } else {
        await user.verifyBeforeUpdateEmail(email.trim());
      }

      // Optional: mirror to Firestore immediately so the UI shows the intent.
      await _db.collection('users').doc(id).update({'email': email.trim()});
      return true;
    } catch (_) {
      return false;
    }
  }
}
