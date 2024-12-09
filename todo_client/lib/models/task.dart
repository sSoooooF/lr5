import 'comment.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final bool done;
  final List<Comment> comments;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.done,
    required this.comments,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      done: json['done'],
      comments: (json['comments'] as List)
          .map((comment) => Comment.fromJson(comment))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'done': done,
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }
}
