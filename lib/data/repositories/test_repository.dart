import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/test_models.dart';

class TestRepository {
  final _uuid = const Uuid();
  final _db = FirebaseFirestore.instance;

  Future<TestPaper> createPaper(
      {required String category,
      required String title,
      int duration = 20}) async {
    final p = TestPaper(
        id: _uuid.v4(),
        category: category,
        title: title,
        durationMinutes: duration);
    await _db.collection('test_papers').doc(p.id).set(p.toMap());
    return p;
  }

  Future<void> addQuestion({
    required String paperId,
    required String text,
    required List<String> options,
    required int correctIndex,
  }) async {
    final q = Question(
        id: _uuid.v4(),
        paperId: paperId,
        text: text,
        options: options,
        correctIndex: correctIndex);
    await _db.collection('questions').doc(q.id).set(q.toMap());
  }

  Future<List<TestPaper>> papersForCategory(String category) async {
    final q = await _db
        .collection('test_papers')
        .where('category', isEqualTo: category)
        .get();
    return q.docs.map((d) => TestPaper.fromMap(d.data())).toList();
  }

  Future<List<Question>> questions(String paperId) async {
    final q = await _db
        .collection('questions')
        .where('paperId', isEqualTo: paperId)
        .get();
    return q.docs.map((d) => Question.fromMap(d.data())).toList();
  }

  Future<void> recordAttempt({
    required String paperId,
    required String userId,
    required int score,
  }) async {
    final a = Attempt(
        id: _uuid.v4(),
        paperId: paperId,
        userId: userId,
        score: score,
        attemptedAt: DateTime.now());
    await _db.collection('attempts').doc(a.id).set({
      ...a.toMap(),
      'attemptedAt': Timestamp.fromDate(a.attemptedAt),
    });
  }

  Future<List<Attempt>> leaderboard(String category) async {
    // Firestore doesn't support join; denormalize via query chain.
    // 1) Fetch papers in category -> ids
    final papersSnap = await _db
        .collection('test_papers')
        .where('category', isEqualTo: category)
        .get();
    final ids = papersSnap.docs.map((d) => d.id).toList();
    if (ids.isEmpty) return [];

    // 2) Query attempts with whereIn (chunk if >10)
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    final attempts = <Attempt>[];
    for (final c in chunks) {
      final snap =
          await _db.collection('attempts').where('paperId', whereIn: c).get();
      attempts.addAll(snap.docs.map((d) {
        final m = d.data();
        return Attempt(
          id: m['id'] as String,
          paperId: m['paperId'] as String,
          userId: m['userId'] as String,
          score: m['score'] as int,
          attemptedAt: (m['attemptedAt'] as Timestamp).toDate(),
        );
      }));
    }

    attempts.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.attemptedAt.compareTo(b.attemptedAt);
    });
    return attempts.take(100).toList();
  }
}
