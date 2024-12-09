import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/task.dart';

class TaskService {
  final String baseUrl;
  final String token;

  TaskService({required this.baseUrl, required this.token});

  Future<List<Task>> fetchTasks({String? filter}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks?filter=$filter'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((task) => Task.fromJson(task)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<void> addComment(String taskId, String comment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/comments'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'content': comment}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add comment');
    }
  }

  Future<void> exportTasksToJson() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/export/json'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);
    } else {
      throw Exception('Failed to export tasks');
    }
  }
}
