class ContentItem {
  final String id, category, title, description, type, urlOrPath;
  ContentItem({required this.id, required this.category, required this.title, required this.description, required this.type, required this.urlOrPath});
  Map<String,Object?> toMap()=>{'id':id,'category':category,'title':title,'description':description,'type':type,'urlOrPath':urlOrPath};
  static ContentItem fromMap(Map<String,Object?> m)=>ContentItem(id:m['id'] as String, category:m['category'] as String, title:m['title'] as String, description:m['description'] as String, type:m['type'] as String, urlOrPath:m['urlOrPath'] as String);
}
