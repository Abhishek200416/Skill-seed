class TestPaper { final String id, category, title; final int durationMinutes;
  TestPaper({required this.id, required this.category, required this.title, this.durationMinutes=20});
  Map<String,Object?> toMap()=>{'id':id,'category':category,'title':title,'durationMinutes':durationMinutes};
  static TestPaper fromMap(Map<String,Object?> m)=>TestPaper(id:m['id'] as String, category:m['category'] as String, title:m['title'] as String, durationMinutes:(m['durationMinutes'] as int?)??20);
}
class Question { final String id, paperId, text; final List<String> options; final int correctIndex;
  Question({required this.id, required this.paperId, required this.text, required this.options, required this.correctIndex});
  Map<String,Object?> toMap()=>{'id':id,'paperId':paperId,'text':text,'options':options.join('||'),'correctIndex':correctIndex};
  static Question fromMap(Map<String,Object?> m)=>Question(id:m['id'] as String, paperId:m['paperId'] as String, text:m['text'] as String, options:(m['options'] as String).split('||'), correctIndex:m['correctIndex'] as int);
}
class Attempt { final String id, paperId, userId; final int score; final DateTime attemptedAt;
  Attempt({required this.id, required this.paperId, required this.userId, required this.score, required this.attemptedAt});
  Map<String,Object?> toMap()=>{'id':id,'paperId':paperId,'userId':userId,'score':score,'attemptedAt':attemptedAt.millisecondsSinceEpoch};
  static Attempt fromMap(Map<String,Object?> m)=>Attempt(id:m['id'] as String, paperId:m['paperId'] as String, userId:m['userId'] as String, score:m['score'] as int, attemptedAt:DateTime.fromMillisecondsSinceEpoch(m['attemptedAt'] as int));
}
