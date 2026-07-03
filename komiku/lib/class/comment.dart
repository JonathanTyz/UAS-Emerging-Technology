class Comment {
  int id;
  String content;
  String createdAt;
  String username;
  String? avatar;
  int? parentId;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.username,
    this.avatar,
    this.parentId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      content: json['content'].toString(),
      createdAt: json['created_at'].toString(),
      username: json['username'].toString(),
      avatar: json['avatar']?.toString(),
      parentId: json['parent_id'] != null
          ? int.parse(json['parent_id'].toString())
          : null,
    );
  }
}
