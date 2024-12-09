class Comment {
  final String id;
  final String user;
  final String content;

  Comment({required this.id, required this.user, required this.content});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      user: json['user'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'content': content,
    };
  }
}
