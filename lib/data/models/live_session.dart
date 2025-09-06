class LiveSession {
  final String id, category, teacherId, title; final DateTime startAt; final String? zoomUrl;
  LiveSession({required this.id, required this.category, required this.teacherId, required this.title, required this.startAt, this.zoomUrl});
  Map<String,Object?> toMap()=>{'id':id,'category':category,'teacherId':teacherId,'title':title,'startAt':startAt.millisecondsSinceEpoch,'zoomUrl':zoomUrl};
  static LiveSession fromMap(Map<String,Object?> m)=>LiveSession(id:m['id'] as String, category:m['category'] as String, teacherId:m['teacherId'] as String, title:m['title'] as String,
    startAt: DateTime.fromMillisecondsSinceEpoch(m['startAt'] as int), zoomUrl:m['zoomUrl'] as String?);
}
